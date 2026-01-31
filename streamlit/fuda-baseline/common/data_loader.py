"""
データローダーモジュール
Snowflakeから財務データとPDFテキストを読み込む
"""

import pandas as pd
from typing import Optional
from snowflake.snowpark import Session


# 10社の企業コード
COMPANY_CODES = [12044, 71768, 73617, 99702, 141634,
                 184226, 244359, 292640, 308582, 325042]


def get_companies(session: Session) -> list[dict]:
    """
    企業一覧を取得

    Args:
        session: Snowpark Session

    Returns:
        list[dict]: 企業情報のリスト
            [{
                'company_code': int,
                'location': str,
                'industry': str,
                'employees': int,
                'capital': float
            }, ...]
    """
    query = """
        SELECT DISTINCT
            "コード" as company_code,
            "本社所在地" as location,
            "業種分類" as industry,
            "従業員数（連結）" as employees,
            "資本金（億円）" as capital
        FROM FINANCIAL_DATA
        ORDER BY company_code
    """
    result = session.sql(query).collect()

    companies = []
    for row in result:
        companies.append({
            'company_code': row['COMPANY_CODE'],
            'location': row['LOCATION'],
            'industry': row['INDUSTRY'],
            'employees': row['EMPLOYEES'],
            'capital': row['CAPITAL']
        })

    return companies


def load_financial_data(session: Session, company_code: int) -> pd.DataFrame:
    """
    財務データ読み込み（3年分）

    Args:
        session: Snowpark Session
        company_code: 企業コード

    Returns:
        pd.DataFrame: 財務データ（3年分）
    """
    query = f"""
        SELECT *
        FROM FINANCIAL_DATA
        WHERE "コード" = {company_code}
        ORDER BY YEAR
    """
    df = session.sql(query).to_pandas()
    return df


def load_pdf_text_from_table(session: Session, company_code: int) -> dict:
    """
    PDFテキストをテーブルから読み込み（フルコンテキスト）

    Args:
        session: Snowpark Session
        company_code: 企業コード

    Returns:
        dict: {
            'full_text': str,
            'character_count': int,
            'fiscal_period': str,
            'submission_date': date,
            'page_count': int,
            'word_count': int,
            'estimated_tokens': float
        }

    Raises:
        ValueError: PDFデータが見つからない場合
    """
    query = f"""
        SELECT
            FULL_TEXT,
            CHARACTER_COUNT,
            FISCAL_PERIOD,
            SUBMISSION_DATE,
            PAGE_COUNT,
            WORD_COUNT
        FROM SECURITIES_REPORTS_TEXT
        WHERE COMPANY_CODE = {company_code}
    """
    result = session.sql(query).collect()

    if not result:
        raise ValueError(f"No PDF data found for company {company_code}")

    row = result[0]
    char_count = row['CHARACTER_COUNT']

    # Token estimation (1 token ≈ 4 characters for Japanese)
    estimated_tokens = char_count / 4

    # Warning if exceeds typical context limits
    if estimated_tokens > 100_000:
        print(f"⚠ Warning: Estimated {estimated_tokens:,.0f} tokens (may exceed context limit)")

    return {
        'full_text': row['FULL_TEXT'],
        'character_count': char_count,
        'fiscal_period': row['FISCAL_PERIOD'],
        'submission_date': row['SUBMISSION_DATE'],
        'page_count': row['PAGE_COUNT'],
        'word_count': row['WORD_COUNT'],
        'estimated_tokens': estimated_tokens
    }


def prepare_pdf_context(full_text: str, max_chars: int = 400_000) -> dict:
    """
    トークン数制限に応じてテキストを調整

    Args:
        full_text: PDF全文
        max_chars: 最大文字数（デフォルト: 400,000文字 ≈ 100,000トークン）

    Returns:
        dict: {
            'text': str (full or truncated),
            'is_truncated': bool,
            'original_length': int,
            'final_length': int
        }
    """
    if len(full_text) <= max_chars:
        return {
            'text': full_text,
            'is_truncated': False,
            'original_length': len(full_text),
            'final_length': len(full_text)
        }

    # Truncate with warning
    truncated = full_text[:max_chars]
    print(f"⚠ Truncated: {len(full_text):,} → {max_chars:,} chars")

    return {
        'text': truncated + "\n\n[... 以降省略 ...]",
        'is_truncated': True,
        'original_length': len(full_text),
        'final_length': max_chars
    }


def calculate_financial_metrics(df: pd.DataFrame) -> dict:
    """
    財務指標を計算（YoY成長率、利益率等）

    Args:
        df: 財務データ（複数年分）

    Returns:
        dict: 計算された財務指標
            {
                'revenue_growth': list[float],  # 売上高成長率（YoY）
                'operating_margin': list[float],  # 営業利益率
                'net_margin': list[float],  # 当期純利益率
                'roa': list[float],  # 総資産利益率
                'roe': list[float],  # 自己資本利益率
                'debt_ratio': list[float],  # 負債比率
                'current_ratio': list[float],  # 流動比率
            }
    """
    metrics = {
        'revenue_growth': [],
        'operating_margin': [],
        'net_margin': [],
        'roa': [],
        'roe': [],
        'debt_ratio': [],
        'current_ratio': []
    }

    # Sort by year
    df = df.sort_values('YEAR')

    for i, row in df.iterrows():
        # Revenue growth (YoY)
        if i > 0:
            prev_revenue = df.iloc[i-1]['売上高']
            if prev_revenue and prev_revenue > 0:
                growth = ((row['売上高'] - prev_revenue) / prev_revenue) * 100
                metrics['revenue_growth'].append(growth)
            else:
                metrics['revenue_growth'].append(None)
        else:
            metrics['revenue_growth'].append(None)

        # Operating margin
        if row['売上高'] and row['売上高'] > 0:
            metrics['operating_margin'].append((row['営業利益'] / row['売上高']) * 100)
        else:
            metrics['operating_margin'].append(None)

        # Net margin
        if row['売上高'] and row['売上高'] > 0:
            metrics['net_margin'].append((row['当期純利益'] / row['売上高']) * 100)
        else:
            metrics['net_margin'].append(None)

        # ROA (Return on Assets)
        if row['総資産'] and row['総資産'] > 0:
            metrics['roa'].append((row['当期純利益'] / row['総資産']) * 100)
        else:
            metrics['roa'].append(None)

        # ROE (Return on Equity)
        if row['純資産'] and row['純資産'] > 0:
            metrics['roe'].append((row['当期純利益'] / row['純資産']) * 100)
        else:
            metrics['roe'].append(None)

        # Debt ratio
        if row['純資産'] and row['純資産'] > 0:
            metrics['debt_ratio'].append((row['負債'] / row['純資産']) * 100)
        else:
            metrics['debt_ratio'].append(None)

        # Current ratio
        if row['流動負債'] and row['流動負債'] > 0:
            metrics['current_ratio'].append((row['流動資産'] / row['流動負債']) * 100)
        else:
            metrics['current_ratio'].append(None)

    return metrics


def load_pdf_from_stage(session: Session, company_code: int) -> list[dict]:
    """
    PDFをStageから読み込み、チャンク化（旧方式 - 後方互換性用）

    Args:
        session: Snowpark Session
        company_code: 企業コード

    Returns:
        list[dict]: PDFチャンクのリスト

    Note:
        この関数は後方互換性のために残されています。
        新しい実装では load_pdf_text_from_table() を使用してください。
    """
    raise NotImplementedError(
        "この関数は廃止されました。load_pdf_text_from_table() を使用してください。"
    )


def load_pdf_data(
    session: Session,
    company_code: int,
    use_table: bool = True
) -> dict:
    """
    PDF データを読み込む（後方互換性用ラッパー）

    Args:
        session: Snowpark Session
        company_code: 企業コード
        use_table: Trueの場合はテーブルから、Falseの場合はStageから読み込む

    Returns:
        dict or list: use_table=Trueの場合はdict、Falseの場合はlist
    """
    if use_table:
        return load_pdf_text_from_table(session, company_code)
    else:
        return load_pdf_from_stage(session, company_code)
