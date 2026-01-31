-- ================================================================
-- PDFテキスト抽出・テーブル投入
-- ================================================================
-- 有価証券報告書PDFから全文を抽出してSECURITIES_REPORTS_TEXTテーブルに投入
-- 使い方: このファイル全体をSnowflake Web UIまたはSnowSQLで実行
-- ================================================================

USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;

USE WAREHOUSE WH_XSMALL;

delete from securities_reports_text;

-- ================================================================
-- Stored Procedure: PDFテキスト抽出・投入処理
-- ================================================================
CREATE OR REPLACE PROCEDURE LOAD_PDF_TEXT_TO_TABLE()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'main'
AS
$$
import re
import json
from snowflake.snowpark import Session

# 10社の企業コード
COMPANY_CODES = [12044, 71768, 73617, 99702, 141634,
                 184226, 244359, 292640, 308582, 325042]


def extract_pdf_text_with_ai(session: Session, pdf_filename: str):
    """
    AI_PARSE_DOCUMENTを使用してPDFテキストを抽出

    Args:
        session: Snowpark Session
        pdf_filename: PDFファイル名（例: 有価証券報告書（12044）.pdf）

    Returns:
        dict: 抽出されたテキストとメタデータ
    """

    # Step 1: AI_PARSE_DOCUMENTを実行
    # 構文: AI_PARSE_DOCUMENT(TO_FILE('@stage', 'filename'), options)
    # 出力: JSON文字列（{"pages": [...], "metadata": {"pageCount": N}}）
    parse_sql = f"""
        SELECT AI_PARSE_DOCUMENT(
            TO_FILE('@SECURITIES_REPORTS', '{pdf_filename}'),
            {{'mode': 'OCR'}}
        ) AS parsed_output
    """

    print(f"  Executing AI_PARSE_DOCUMENT for {pdf_filename}...")

    try:
        result = session.sql(parse_sql).collect()
    except Exception as e:
        raise ValueError(f"AI_PARSE_DOCUMENT failed for {pdf_filename}: {str(e)}")

    if not result or not result[0]['PARSED_OUTPUT']:
        raise ValueError(f"AI_PARSE_DOCUMENT returned empty result for {pdf_filename}")

    # Step 2: AI_PARSE_DOCUMENTの出力を取得（JSON文字列）
    parsed_json_str = result[0]['PARSED_OUTPUT']

    # Step 3: JSON文字列をパース
    try:
        parsed_data = json.loads(parsed_json_str)
    except json.JSONDecodeError as e:
        raise ValueError(f"Failed to parse AI_PARSE_DOCUMENT output as JSON: {str(e)}")

    # Step 4: テキストを抽出
    # 出力形式: {"pages": [{"content": "...", "index": 0}, ...], "metadata": {"pageCount": N}}
    if 'pages' in parsed_data and isinstance(parsed_data['pages'], list):
        # pages配列からcontentを抽出して結合
        page_texts = [page.get('content', '') for page in parsed_data['pages']]
        full_text = '\n\n'.join(page_texts)
    elif 'content' in parsed_data:
        # page_split=falseの場合（念のため対応）
        full_text = parsed_data['content']
    else:
        raise ValueError(f"Unexpected AI_PARSE_DOCUMENT output structure: {list(parsed_data.keys())}")

    # メタデータからページ数を取得
    metadata = parsed_data.get('metadata', {})
    page_count = metadata.get('pageCount', 0)

    # Step 5: メタデータ抽出（既存ロジックを維持）
    # 注: AI_PARSE_DOCUMENTが既に高品質なテキストを出力するため、前処理は不要
    first_page = full_text[:5000]  # 最初の5000文字を対象

    # 決算期（例: 2025年3月期）
    fiscal_match = re.search(r'(\d{4})年(\d{1,2})月期', first_page)
    fiscal_period = fiscal_match.group(0) if fiscal_match else None
    fiscal_year = int(fiscal_match.group(1)) if fiscal_match else None

    # 提出日（例: 2025年6月27日）
    date_match = re.search(r'(\d{4})年(\d{1,2})月(\d{1,2})日', first_page)
    submission_date = None
    if date_match:
        year, month, day = date_match.groups()
        submission_date = f"{year}-{month.zfill(2)}-{day.zfill(2)}"

    # Step 6: 品質チェック（警告のみ）
    if len(full_text) < 10000:
        print(f"  ⚠ Warning: Extracted text is unusually short ({len(full_text)} chars)")

    return {
        'full_text': full_text,
        'page_count': page_count if page_count > 0 else len(page_texts),
        'character_count': len(full_text),
        'word_count': len(full_text.split()),
        'fiscal_period': fiscal_period,
        'fiscal_year': fiscal_year,
        'submission_date': submission_date
    }


def main(session: Session):
    """
    メイン処理: 全PDFを処理してテーブルに投入

    Args:
        session: Snowpark Session（自動的に渡される）

    Returns:
        str: 処理結果メッセージ
    """
    print("=" * 60)
    print("PDF Text Extraction and Loading")
    print("=" * 60)

    # まずステージ内のファイルを確認
    print("\nChecking files in @SECURITIES_REPORTS stage...")
    try:
        stage_files = session.sql("LIST @SECURITIES_REPORTS").collect()
        print(f"Found {len(stage_files)} files in stage:")
        for file in stage_files:
            print(f"  - {file['name']}")
    except Exception as e:
        print(f"Error listing stage files: {str(e)}")
    print()

    success_count = 0

    for company_code in COMPANY_CODES:
        pdf_filename = f"有価証券報告書（{company_code}）.pdf"
        stage_path = f"@SECURITIES_REPORTS/{pdf_filename}"

        print(f"\n[{company_code}] Processing: {pdf_filename}")
        print(f"  Stage path: {stage_path}")

        # PDF処理（AI_PARSE_DOCUMENTを使用）
        print(f"  Step 1: Extracting text from PDF using AI_PARSE_DOCUMENT...")
        extracted = extract_pdf_text_with_ai(session, pdf_filename)

        print(f"  Step 2: Extracted {extracted['character_count']:,} characters, {extracted['page_count']} pages")

        # SQL用にエスケープ
        print(f"  Step 3: Escaping text for SQL...")
        full_text_escaped = extracted['full_text'].replace("'", "''")
        fiscal_period_escaped = extracted['fiscal_period'].replace("'", "''") if extracted['fiscal_period'] else None

        # INSERT文構築
        print(f"  Step 4: Building INSERT statement...")
        insert_sql = f"""
            INSERT INTO SECURITIES_REPORTS_TEXT (
                COMPANY_CODE,
                FULL_TEXT,
                DOCUMENT_TITLE,
                SUBMISSION_DATE,
                FISCAL_PERIOD,
                FISCAL_YEAR,
                PAGE_COUNT,
                CHARACTER_COUNT,
                WORD_COUNT,
                PDF_FILE_NAME,
                STAGE_PATH
            ) VALUES (
                {company_code},
                '{full_text_escaped}',
                '有価証券報告書',
                {f"'{extracted['submission_date']}'" if extracted['submission_date'] else 'NULL'},
                {f"'{fiscal_period_escaped}'" if fiscal_period_escaped else 'NULL'},
                {extracted['fiscal_year'] if extracted['fiscal_year'] else 'NULL'},
                {extracted['page_count']},
                {extracted['character_count']},
                {extracted['word_count']},
                '{pdf_filename}',
                '{stage_path}'
            )
        """

        # データ投入
        print(f"  Step 5: Executing INSERT statement...")
        result = session.sql(insert_sql).collect()
        print(f"  Step 6: INSERT executed, result: {result}")

        # トークン数推定（1 token ≈ 4文字）
        estimated_tokens = extracted['character_count'] / 4

        print(f"  ✓ SUCCESS: Loaded {company_code}")
        print(f"    - Pages: {extracted['page_count']}")
        print(f"    - Characters: {extracted['character_count']:,}")
        print(f"    - Estimated tokens: {estimated_tokens:,.0f}")
        if extracted['fiscal_period']:
            print(f"    - Fiscal period: {extracted['fiscal_period']}")
        if estimated_tokens > 100_000:
            print(f"    ⚠ Warning: Estimated tokens exceed 100K")

        success_count += 1

    print()
    print("=" * 60)
    print(f"Completed: {success_count} PDFs loaded successfully")
    print("=" * 60)

    # 検証クエリ実行
    result = session.sql("""
        SELECT
            COUNT(*) as total,
            AVG(CHARACTER_COUNT) as avg_chars,
            MIN(CHARACTER_COUNT) as min_chars,
            MAX(CHARACTER_COUNT) as max_chars
        FROM SECURITIES_REPORTS_TEXT
    """).collect()

    if result and result[0]['TOTAL'] > 0:
        row = result[0]
        print()
        print("Verification:")
        print(f"  Total records: {row['TOTAL']}")

        # NULLチェック付きでフォーマット
        if row['AVG_CHARS'] is not None:
            print(f"  Average characters: {row['AVG_CHARS']:,.0f}")

        if row['MIN_CHARS'] is not None and row['MAX_CHARS'] is not None:
            print(f"  Character range: {row['MIN_CHARS']:,} - {row['MAX_CHARS']:,}")

        # トークン数推定
        if row['AVG_CHARS'] is not None:
            avg_tokens = row['AVG_CHARS'] / 4
            print(f"  Estimated tokens (avg): {avg_tokens:,.0f}")

        if row['MAX_CHARS'] is not None:
            max_tokens = row['MAX_CHARS'] / 4
            print(f"  Estimated tokens (max): {max_tokens:,.0f}")

            if max_tokens > 128_000:
                print("  ⚠ Warning: Some PDFs may exceed 128K token limit")
            elif max_tokens > 100_000:
                print("  ⚠ Warning: Some PDFs approach 100K+ tokens")
            else:
                print("  ✓ All PDFs within safe token limits")

    return f"PDF text loading completed: {success_count} PDFs loaded successfully"
$$;

-- ================================================================
-- 実行: Stored Procedureを呼び出し
-- ================================================================
CALL LOAD_PDF_TEXT_TO_TABLE();

-- ================================================================
-- 確認: 投入されたデータを確認
-- ================================================================
SELECT
    COMPANY_CODE,
    CHARACTER_COUNT,
    PAGE_COUNT,
    FISCAL_PERIOD,
    SUBMISSION_DATE,
    LEFT(FULL_TEXT, 100) AS TEXT_PREVIEW
FROM SECURITIES_REPORTS_TEXT
ORDER BY COMPANY_CODE;

-- 統計情報
SELECT
    COUNT(*) as total_records,
    AVG(CHARACTER_COUNT) as avg_characters,
    MIN(CHARACTER_COUNT) as min_characters,
    MAX(CHARACTER_COUNT) as max_characters,
    AVG(PAGE_COUNT) as avg_pages,
    MIN(PAGE_COUNT) as min_pages,
    MAX(PAGE_COUNT) as max_pages
FROM SECURITIES_REPORTS_TEXT;
