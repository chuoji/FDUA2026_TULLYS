"""
プロンプトテンプレート
Fact Sheet生成と提案書生成用のプロンプト
"""

# Fact Sheet生成プロンプト（フルコンテキスト版）
FACT_SHEET_PROMPT = """
あなたは経営コンサルタントです。以下の企業情報と財務データ、有価証券報告書から、
Fact Sheetを作成してください。

# 企業情報
- 企業コード: {company_code}
- 本社所在地: {location}
- 業種: {industry}
- 従業員数: {employees}人
- 資本金: {capital}億円

# 財務データ（3年分）
{financial_summary}

# 有価証券報告書（全文）
{pdf_full_text}

注意: 上記は有価証券報告書の全文です。必要な情報を抽出して分析してください。

# 出力形式（JSON）
{{
  "企業概要": "",
  "外部環境分析": "",
  "地域特性": "",
  "財務分析": {{
    "売上推移": "",
    "利益率": "",
    "CF状況": ""
  }},
  "課題仮説": [],
  "成長機会": [],
  "リスク": [],
  "施策候補": [],
  "期待効果": ""
}}
"""

# 提案書生成プロンプト
PROPOSAL_PROMPT = """
あなたは大手銀行の支店長です。以下のFact Sheetと評価基準に基づき、
建設業向けの成長戦略提案書を作成してください。

# Fact Sheet
{fact_sheet_json}

# 評価基準（5つの視点）
1. 全体構成: 過去3年の分析と未来の戦略が論理的に接続されているか
2. 地域性: 所在地の特性（{location}）を踏まえた提案か
3. 業界特性: {industry}の販路・商流を理解した提案か
4. GX/DX: 環境技術・省力化技術への対応策を提案できているか
5. 人材/需要: 需要減退・人材不足への実効性ある解決策を示せているか

# 提案書構成（必須）
1. 企業概要・分析
   - 外部環境や地域特性
   - 財務情報の分析
   - 課題の抽出
2. 成長戦略、提案
3. 効果試算、ロードマップ

# 制約
- 最大15,000字（A4 10ページ以内）
- 根拠（財務データ、PDF引用）を明記
- 断定的表現を避け、提案口調で記述

# 出力
提案書本文をMarkdown形式で出力してください。
"""


def format_financial_summary(df, metrics: dict) -> str:
    """
    財務データを要約文字列に整形

    Args:
        df: 財務データDataFrame
        metrics: 計算された財務指標

    Returns:
        str: 整形された財務サマリー
    """
    summary_lines = []

    summary_lines.append("## 財務データ（3年推移）\n")

    # Sort by year
    df = df.sort_values('YEAR')

    for idx, (i, row) in enumerate(df.iterrows()):
        year = row['YEAR']
        summary_lines.append(f"### {year}年度")

        # P/L
        summary_lines.append(f"- 売上高: {row['売上高']:,}円")
        summary_lines.append(f"- 営業利益: {row['営業利益']:,}円 (利益率: {metrics['operating_margin'][idx]:.2f}%)")
        summary_lines.append(f"- 経常利益: {row['経常利益']:,}円")
        summary_lines.append(f"- 当期純利益: {row['当期純利益']:,}円 (利益率: {metrics['net_margin'][idx]:.2f}%)")

        # Growth rate (if not first year)
        if metrics['revenue_growth'][idx] is not None:
            summary_lines.append(f"- 売上高成長率（前年比）: {metrics['revenue_growth'][idx]:+.2f}%")

        # B/S
        summary_lines.append(f"- 総資産: {row['総資産']:,}円")
        summary_lines.append(f"- 純資産: {row['純資産']:,}円")
        summary_lines.append(f"- 負債: {row['負債']:,}円")

        # Ratios
        if metrics['roa'][idx] is not None:
            summary_lines.append(f"- ROA: {metrics['roa'][idx]:.2f}%")
        if metrics['roe'][idx] is not None:
            summary_lines.append(f"- ROE: {metrics['roe'][idx]:.2f}%")
        if metrics['debt_ratio'][idx] is not None:
            summary_lines.append(f"- 負債比率: {metrics['debt_ratio'][idx]:.2f}%")

        # C/F
        summary_lines.append(f"- 営業CF: {row['営業活動によるキャッシュ・フロー']:,}円")
        summary_lines.append(f"- 投資CF: {row['投資活動によるキャッシュ・フロー']:,}円")
        summary_lines.append(f"- 財務CF: {row['財務活動によるキャッシュ・フロー']:,}円")
        summary_lines.append(f"- 期末現金残高: {row['現金及び現金同等物期末残高']:,}円")

        summary_lines.append("")

    return "\n".join(summary_lines)


def format_fact_sheet_prompt(
    company_info: dict,
    financial_data,
    financial_metrics: dict,
    pdf_full_text: str
) -> str:
    """
    Fact Sheetプロンプトを構築

    Args:
        company_info: 企業情報
        financial_data: 財務データDataFrame
        financial_metrics: 計算された財務指標
        pdf_full_text: PDF全文

    Returns:
        str: 構築されたプロンプト
    """
    financial_summary = format_financial_summary(financial_data, financial_metrics)

    return FACT_SHEET_PROMPT.format(
        company_code=company_info['company_code'],
        location=company_info['location'],
        industry=company_info['industry'],
        employees=company_info.get('employees', 'N/A'),
        capital=company_info.get('capital', 'N/A'),
        financial_summary=financial_summary,
        pdf_full_text=pdf_full_text
    )


def format_proposal_prompt(
    fact_sheet: dict,
    company_info: dict
) -> str:
    """
    提案書プロンプトを構築

    Args:
        fact_sheet: Fact Sheet（JSON）
        company_info: 企業情報

    Returns:
        str: 構築されたプロンプト
    """
    import json

    # Convert fact_sheet to JSON string
    fact_sheet_json = json.dumps(fact_sheet, ensure_ascii=False, indent=2)

    return PROPOSAL_PROMPT.format(
        fact_sheet_json=fact_sheet_json,
        location=company_info['location'],
        industry=company_info['industry']
    )
