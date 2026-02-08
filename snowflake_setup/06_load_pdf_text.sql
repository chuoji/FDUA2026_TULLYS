-- ================================================================
-- PDFテキスト抽出・テーブル投入
-- ================================================================
-- 有価証券報告書PDFから全文を抽出してSECURITIES_REPORTS_TEXTテーブルに投入
-- 使い方: このファイル全体をSnowflake Web UIまたはSnowSQLで実行
-- ================================================================

USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;

USE WAREHOUSE WH_XSMALL;

delete from securities_reports_text_CHUNKED;

-- ================================================================
-- Stored Procedure: PDFテキスト抽出・投入処理
-- ================================================================
CREATE OR REPLACE PROCEDURE LOAD_SECURITIES_REPORTS_CHUNKS()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'main'
AS
$$
import re
import json
from typing import List, Dict, Any, Tuple, Optional
from snowflake.snowpark import Session

COMPANY_CODES = [12044, 71768, 73617, 99702, 141634,
                 184226, 244359, 292640, 308582, 325042]

L1_ALLOWED = [
    "【表紙】",
    "第1【企業の概況】",
    "第2【事業の状況】",
    "第3【設備の状況】",
    "第4【提出会社の状況】",
    "第5【経理の状況】",
    "【注記事項】",
]

L2_ALLOWED_BY_L1 = {
    "第1【企業の概況】": [
        "1【主要な経営指標等の推移】",
        "2【沿革】",
        "3【事業の内容】",
        "4【関係会社の状況】",
        "5【従業員の状況】",
    ],
    "第2【事業の状況】": [
        "1【経営方針、経営環境及び対処すべき課題等】",
        "2【サステナビリティに関する考え方及び取組】",
        "3【事業等のリスク】",
        "4【経営者による財政状態、経営成績及びキャッシュ・フローの状況の分析】",
        "5【経営上の重要な契約等】",
        "6【研究開発活動】",
    ],
    "第3【設備の状況】": [
        "1【設備投資等の概要】",
        "2【主要な設備の状況】",
        "3【設備の新設、除却等の計画】",
    ],
    "第4【提出会社の状況】": [
        "1【株式等の状況】",
        "2【自己株式の取得等の状況】",
        "3【配当政策】",
        "4【コーポレート・ガバナンスの状況等】",
    ],
    "第5【経理の状況】": [
        "1【財務諸表等】",
    ],
}

RE_MD_HEADING_LINE = re.compile(r'^(?P<h>#{1,6})\s+(?P<title>.+?)\s*$', re.MULTILINE)
RE_L1_PLAIN_LINE   = re.compile(r'^(【表紙】|第[1-5]【[^】]+】|【注記事項】)\s*$', re.MULTILINE)
RE_L2_CANON        = re.compile(r'^(?P<num>\d+)\s*【(?P<title>[^】]+)】$')

def _norm(s: str) -> str:
    s = s.replace("\u3000", " ")
    s = re.sub(r"\s+", " ", s).strip()
    return s

def _canon_l2(title: str) -> Optional[str]:
    t = _norm(title)
    m = RE_L2_CANON.match(t)
    if not m:
        return None
    return f"{m.group('num')}【{m.group('title').strip()}】"

def _nullify(v):
    if v is None:
        return None
    if isinstance(v, str):
        t = v.strip()
        if t == "" or t.lower() in ("none", "null"):
            return None
        return t
    return v

def split_by_chapter_and_item(full_text: str) -> List[Dict[str, Any]]:
    text = full_text.replace("\r\n", "\n").replace("\r", "\n")

    hits: List[Tuple[int, int, str, bool]] = []
    for m in RE_MD_HEADING_LINE.finditer(text):
        hits.append((m.start(), m.end(), _norm(m.group("title")), True))
    for m in RE_L1_PLAIN_LINE.finditer(text):
        hits.append((m.start(), m.end(), _norm(m.group(1)), False))
    hits.sort(key=lambda x: x[0])

    l1_set = set(L1_ALLOWED)
    l2_allowed_sets = {k: set(v) for k, v in L2_ALLOWED_BY_L1.items()}

    accepted: List[Tuple[int, int, int, str, str]] = []
    cur_l1: Optional[str] = None

    for start, end, t, _is_md in hits:
        if t in l1_set:
            cur_l1 = t
            accepted.append((start, end, 1, cur_l1, cur_l1))
            continue

        if cur_l1 and cur_l1 in l2_allowed_sets:
            canon = _canon_l2(t)
            if canon and canon in l2_allowed_sets[cur_l1]:
                accepted.append((start, end, 2, cur_l1, canon))

    chunks: List[Dict[str, Any]] = []
    for i, (_h_start, h_end, level, l1, title) in enumerate(accepted):
        body_start = h_end
        body_end = accepted[i + 1][0] if i + 1 < len(accepted) else len(text)
        body = text[body_start:body_end].strip()
        if not body:
            continue

        chunks.append({
            "l1": l1,
            "l2": title if level == 2 else None,
            "text": body,
            "start": body_start,
            "end": body_end,
            "char_count": len(body),
        })
    return chunks

def extract_pdf_text_with_ai(session: Session, pdf_filename: str) -> Dict[str, Any]:
    parse_sql = f"""
        SELECT AI_PARSE_DOCUMENT(
            TO_FILE('@SECURITIES_REPORTS', '{pdf_filename}'),
            OBJECT_CONSTRUCT('mode','LAYOUT', 'page_split', FALSE)
        ) AS parsed_output
    """
    result = session.sql(parse_sql).collect()
    if not result or not result[0]["PARSED_OUTPUT"]:
        raise ValueError(f"AI_PARSE_DOCUMENT returned empty result for {pdf_filename}")

    parsed_data = json.loads(result[0]["PARSED_OUTPUT"])

    if "content" in parsed_data and isinstance(parsed_data["content"], str):
        full_text = parsed_data["content"]
    elif "pages" in parsed_data and isinstance(parsed_data["pages"], list):
        page_texts = [p.get("content", "") for p in parsed_data["pages"]]
        full_text = "\n\n".join(page_texts)
    else:
        raise ValueError(f"Unexpected AI_PARSE_DOCUMENT output structure: {list(parsed_data.keys())}")

    metadata = parsed_data.get("metadata", {})
    page_count = metadata.get("pageCount", None)

    first_page = full_text[:5000]
    fiscal_match = re.search(r"(\d{4})年(\d{1,2})月期", first_page)
    fiscal_period = fiscal_match.group(0) if fiscal_match else None
    fiscal_year = int(fiscal_match.group(1)) if fiscal_match else None

    date_match = re.search(r"(\d{4})年(\d{1,2})月(\d{1,2})日", first_page)
    submission_date = None
    if date_match:
        y, m, d = date_match.groups()
        submission_date = f"{y}-{m.zfill(2)}-{d.zfill(2)}"

    return {
        "chunks": split_by_chapter_and_item(full_text),
        "page_count": page_count,
        "fiscal_period": fiscal_period,
        "fiscal_year": fiscal_year,
        "submission_date": submission_date,
    }

def main(session: Session) -> str:
    print("=" * 60)
    print("Load chunks: 1 row per chunk")
    print("=" * 60)

    insert_sql = """
      INSERT INTO SECURITIES_REPORTS_CHUNKS (
        COMPANY_CODE, CHUNK_ID, L1_TITLE, L2_TITLE,
        CHUNK_TEXT, CHAR_COUNT, START_POS, END_POS,
        DOCUMENT_TITLE, SUBMISSION_DATE, FISCAL_PERIOD, FISCAL_YEAR,
        PAGE_COUNT, PDF_FILE_NAME, STAGE_PATH, EXTRACTION_METHOD
      )
      SELECT
        TRY_TO_NUMBER(NULLIF(?, 'None')),
        TRY_TO_NUMBER(NULLIF(?, 'None')),
        ?,
        ?,
        ?,
        TRY_TO_NUMBER(NULLIF(?, 'None')),
        TRY_TO_NUMBER(NULLIF(?, 'None')),
        TRY_TO_NUMBER(NULLIF(?, 'None')),
        ?,
        TRY_TO_DATE(NULLIF(?, 'None')),
        ?,
        TRY_TO_NUMBER(NULLIF(?, 'None')),
        TRY_TO_NUMBER(NULLIF(?, 'None')),
        ?,
        ?,
        ?
    """

    success_count = 0
    total_chunks = 0

    for company_code in COMPANY_CODES:
        pdf_filename = f"有価証券報告書（{company_code}）.pdf"
        stage_path = f"@SECURITIES_REPORTS/{pdf_filename}"

        print(f"\n[{company_code}] Extracting + chunking: {pdf_filename}")
        extracted = extract_pdf_text_with_ai(session, pdf_filename)

        # 再実行対応：会社単位で削除
        session.sql("DELETE FROM SECURITIES_REPORTS_CHUNKS WHERE COMPANY_CODE = ?", params=[company_code]).collect()

        chunks = extracted["chunks"]
        print(f"  chunks = {len(chunks)}")

        sub_date = _nullify(extracted.get("submission_date"))
        fiscal_period = _nullify(extracted.get("fiscal_period"))
        fiscal_year = extracted.get("fiscal_year")
        page_count = extracted.get("page_count")

        for idx, c in enumerate(chunks, start=1):
            params = [
                str(company_code),
                str(idx),
                _nullify(c.get("l1")),
                _nullify(c.get("l2")),
                c.get("text", ""),
                str(_nullify(c.get("char_count"))),
                str(_nullify(c.get("start"))),
                str(_nullify(c.get("end"))),
                "有価証券報告書",
                sub_date,
                fiscal_period,
                str(fiscal_year) if fiscal_year is not None else None,  # ← 'None'文字列禁止
                str(page_count) if page_count is not None else None,
                pdf_filename,
                stage_path,
                "AI_PARSE_DOCUMENT_LAYOUT",
            ]
            session.sql(insert_sql, params=params).collect()

        success_count += 1
        total_chunks += len(chunks)
        print(f"  ✓ Loaded {company_code}: {len(chunks)} chunks")

    print()
    print("=" * 60)
    print(f"Completed: {success_count} PDFs, {total_chunks} chunks inserted")
    print("=" * 60)

    return f"Loaded {success_count} PDFs, inserted {total_chunks} chunks into SECURITIES_REPORTS_CHUNKS"
$$;

-- ================================================================
-- 実行: Stored Procedureを呼び出し
-- ================================================================
CALL LOAD_SECURITIES_REPORTS_CHUNKS();

-- ================================================================
-- 確認: 投入されたデータを確認
-- ================================================================
SELECT
  COMPANY_CODE,
  COUNT(*) AS chunk_rows,
  MIN(CHUNK_ID) AS min_chunk,
  MAX(CHUNK_ID) AS max_chunk
FROM SECURITIES_REPORTS_CHUNKS
GROUP BY COMPANY_CODE
ORDER BY COMPANY_CODE;

-- fiscal_year が NULL になっているか確認
SELECT COMPANY_CODE, CHUNK_ID, FISCAL_YEAR, FISCAL_PERIOD, SUBMISSION_DATE
FROM SECURITIES_REPORTS_CHUNKS
WHERE FISCAL_YEAR IS NULL
ORDER BY COMPANY_CODE, CHUNK_ID
LIMIT 50;


SELECT * FROM SECURITIES_REPORTS_CHUNKS LIMIT 10;

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
