"""
検証モジュール
提案書の品質を検証
"""

import re
import pandas as pd


def validate_proposal(proposal_text: str, financial_data: pd.DataFrame, pdf_data: dict) -> dict:
    """
    提案書を検証

    Args:
        proposal_text: 提案書本文
        financial_data: 財務データDataFrame
        pdf_data: PDF全文データ

    Returns:
        dict: 検証結果
            {
                'format': {...},
                'numerical': {...},
                'coverage': {...},
                'overall': {...},
                'suggestions': [...]
            }
    """
    # 1. 形式チェック
    format_result = validate_format(proposal_text)

    # 2. 数値整合性チェック
    numerical_result = validate_numerical_consistency(proposal_text, financial_data)

    # 3. カバレッジチェック
    coverage_result = validate_coverage(proposal_text, pdf_data)

    # 4. 総合評価
    overall_result = calculate_overall_score(format_result, numerical_result, coverage_result)

    # 5. 改善提案
    suggestions = generate_suggestions(format_result, numerical_result, coverage_result)

    return {
        'format': format_result,
        'numerical': numerical_result,
        'coverage': coverage_result,
        'overall': overall_result,
        'suggestions': suggestions
    }


def validate_format(proposal_text: str) -> dict:
    """
    形式チェック

    Args:
        proposal_text: 提案書本文

    Returns:
        dict: 形式チェック結果
    """
    char_count = len(proposal_text)

    # 必須セクションの検出
    required_sections = [
        r'企業概要|企業分析|概要.*分析',
        r'成長戦略|戦略.*提案|提案',
        r'効果試算|ロードマップ|実行計画'
    ]

    missing_sections = []
    for i, pattern in enumerate(required_sections, 1):
        if not re.search(pattern, proposal_text, re.IGNORECASE):
            section_names = ['企業概要・分析', '成長戦略・提案', '効果試算・ロードマップ']
            missing_sections.append(section_names[i - 1])

    has_required_sections = len(missing_sections) == 0

    # 文字数チェック（15,000字以内）
    char_limit_ok = char_count <= 15000

    passed = has_required_sections and char_limit_ok

    return {
        'char_count': char_count,
        'char_limit_ok': char_limit_ok,
        'has_required_sections': has_required_sections,
        'missing_sections': missing_sections,
        'passed': passed
    }


def validate_numerical_consistency(proposal_text: str, financial_data: pd.DataFrame) -> dict:
    """
    数値整合性チェック

    Args:
        proposal_text: 提案書本文
        financial_data: 財務データDataFrame

    Returns:
        dict: 数値整合性チェック結果
    """
    # 提案書から数値を抽出（カンマ区切りの数値、小数点付き数値）
    number_pattern = r'[\d,]+\.?\d*(?:億円|百万円|万円|千円|円|%|人|件)'
    numbers = re.findall(number_pattern, proposal_text)

    numbers_found = len(numbers)

    # 簡易的な範囲チェック（実際の財務データとの照合は複雑なため省略）
    out_of_range = 0
    issues = []

    # 売上高の範囲チェック（例）
    if not financial_data.empty and 'revenue' in financial_data.columns:
        revenue_values = financial_data['revenue'].dropna()
        if len(revenue_values) > 0:
            min_revenue = revenue_values.min()
            max_revenue = revenue_values.max()

            # 提案書から「売上」に関連する数値を探す
            revenue_mentions = re.findall(r'売上.*?([\d,]+\.?\d*)億円', proposal_text)
            for val_str in revenue_mentions:
                try:
                    val = float(val_str.replace(',', ''))
                    if val < min_revenue * 0.5 or val > max_revenue * 2.0:
                        out_of_range += 1
                        issues.append(f"売上高 {val}億円 が財務データの範囲外")
                except ValueError:
                    pass

    passed = out_of_range == 0 and numbers_found > 0

    return {
        'numbers_found': numbers_found,
        'out_of_range': out_of_range,
        'issues': issues,
        'passed': passed
    }


def validate_coverage(proposal_text: str, pdf_data: dict) -> dict:
    """
    カバレッジチェック

    Args:
        proposal_text: 提案書本文
        pdf_data: PDF全文データ

    Returns:
        dict: カバレッジチェック結果
    """
    # 財務データ引用のカウント（キーワードベース）
    financial_keywords = [
        '売上', '営業利益', '経常利益', '純利益', '総資産', '負債',
        '純資産', '自己資本比率', 'ROE', 'ROA', 'キャッシュフロー'
    ]
    financial_refs = sum(1 for kw in financial_keywords if kw in proposal_text)

    # PDF引用のカウント（「有価証券報告書」「報告書」などの言及）
    pdf_keywords = ['有価証券報告書', '報告書', '事業内容', 'リスク', '経営方針']
    pdf_refs = sum(1 for kw in pdf_keywords if kw in proposal_text)

    # 根拠の明示（「によると」「に基づき」などの表現）
    evidence_patterns = [r'によると', r'に基づき', r'から読み取れる', r'より']
    has_evidence = any(re.search(pattern, proposal_text) for pattern in evidence_patterns)

    # 最低限の引用数
    min_financial_refs = 3
    min_pdf_refs = 1

    passed = (
        financial_refs >= min_financial_refs and
        pdf_refs >= min_pdf_refs and
        has_evidence
    )

    return {
        'financial_refs': financial_refs,
        'pdf_refs': pdf_refs,
        'has_evidence': has_evidence,
        'passed': passed
    }


def calculate_overall_score(format_result: dict, numerical_result: dict, coverage_result: dict) -> dict:
    """
    総合評価スコアを計算

    Args:
        format_result: 形式チェック結果
        numerical_result: 数値整合性チェック結果
        coverage_result: カバレッジチェック結果

    Returns:
        dict: 総合評価
    """
    # スコア計算（0-100点）
    score = 0

    # 形式チェック（40点）
    if format_result['passed']:
        score += 40
    elif format_result['char_limit_ok']:
        score += 20
    elif format_result['has_required_sections']:
        score += 20

    # 数値整合性（30点）
    if numerical_result['passed']:
        score += 30
    elif numerical_result['numbers_found'] > 0:
        score += 15

    # カバレッジ（30点）
    if coverage_result['passed']:
        score += 30
    else:
        # 部分点
        if coverage_result['financial_refs'] >= 1:
            score += 10
        if coverage_result['pdf_refs'] >= 1:
            score += 10
        if coverage_result['has_evidence']:
            score += 10

    passed = (
        format_result['passed'] and
        numerical_result['passed'] and
        coverage_result['passed']
    )

    return {
        'score': score,
        'passed': passed
    }


def generate_suggestions(format_result: dict, numerical_result: dict, coverage_result: dict) -> list:
    """
    改善提案を生成

    Args:
        format_result: 形式チェック結果
        numerical_result: 数値整合性チェック結果
        coverage_result: カバレッジチェック結果

    Returns:
        list: 改善提案のリスト
    """
    suggestions = []

    # 形式に関する提案
    if not format_result['char_limit_ok']:
        suggestions.append(f"文字数が{format_result['char_count']:,}字で、15,000字を超えています。削減してください。")

    if format_result['missing_sections']:
        suggestions.append(f"以下のセクションが欠けています: {', '.join(format_result['missing_sections'])}")

    # 数値に関する提案
    if numerical_result['numbers_found'] == 0:
        suggestions.append("具体的な数値が含まれていません。財務データから数値を引用してください。")

    if numerical_result['out_of_range'] > 0:
        suggestions.append(f"{numerical_result['out_of_range']}個の数値が財務データの範囲外です。確認してください。")

    # カバレッジに関する提案
    if coverage_result['financial_refs'] < 3:
        suggestions.append("財務データの引用が不足しています。売上高、利益率、資産などを明記してください。")

    if coverage_result['pdf_refs'] < 1:
        suggestions.append("有価証券報告書からの引用が不足しています。事業内容やリスクを記載してください。")

    if not coverage_result['has_evidence']:
        suggestions.append("根拠の明示が不足しています。「によると」「に基づき」などの表現で出典を明示してください。")

    return suggestions
