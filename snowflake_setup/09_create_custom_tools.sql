-- ================================================================
-- カスタムツール作成
-- ================================================================
-- Cortex Agentで使用するカスタムツール（Python UDF）を作成
-- 前提: 10_create_cortex_agent.sql を実行済み
-- ================================================================

USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;
USE WAREHOUSE WH_XSMALL;

-- ================================================================
-- Step 1: Stage確認（Word出力用）
-- ================================================================
-- 注: GENERATED_PROPOSALSは既に03_create_stages.sqlで作成済み

-- Stageの確認
SHOW STAGES LIKE 'GENERATED_PROPOSALS';

-- ================================================================
-- Step 2: カスタムツール1 - Word出力関数（Stored Procedure）
-- ================================================================
CREATE OR REPLACE PROCEDURE EXPORT_PROPOSAL_TO_WORD(
    company_code INTEGER,
    proposal_text STRING,
    phase STRING
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python', 'python-docx', 'markdown2')
HANDLER = 'export_to_word'
AS
$$
import re
import json
from datetime import datetime
from io import BytesIO
from snowflake.snowpark import Session
from docx import Document
from docx.shared import Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT

# ------------------------------------------------------------
# 文字化け（□）対策：日本語フォントを明示
# ※環境によっては Word 側にフォントが無いと置換されるので、
#   まずは一般的なフォント名を指定（Meiryo / Yu Gothic / MS Gothic）
# ------------------------------------------------------------
JP_FONT = "Meiryo"

def _apply_jp_font_to_paragraph(paragraph, size_pt: int = 11):
    """段落内の run に日本語フォントを強制適用（□対策）"""
    for run in paragraph.runs:
        run.font.name = JP_FONT
        run.font.size = Pt(size_pt)

def _compact_paragraph(paragraph, line_spacing: float = 1.15, space_after_pt: int = 2, space_before_pt: int = 0):
    """段落の余白を詰めてページ膨張を防ぐ"""
    fmt = paragraph.paragraph_format
    fmt.line_spacing = line_spacing
    fmt.space_before = Pt(space_before_pt)
    fmt.space_after = Pt(space_after_pt)

def _is_markdown_table_row(line: str) -> bool:
    s = line.strip()
    return s.startswith("|") and "|" in s

def _is_table_separator_row(line: str) -> bool:
    """
    |---|---| や |:---|---:| のような区切り行を判定
    """
    s = line.strip().strip("|").strip()
    if not s:
        return False
    parts = [p.strip() for p in s.split("|")]
    if len(parts) < 2:
        return False
    for p in parts:
        if not p:
            return False
        # :---: などを許可
        p2 = p.replace(":", "")
        if not p2 or set(p2) != {"-"}:
            return False
    return True

def _parse_md_table_lines(table_lines):
    """Markdown表の行をセル配列に変換（区切り行は除外）"""
    rows = []
    for line in table_lines:
        line = line.strip()
        if not line:
            continue
        if _is_table_separator_row(line):
            continue
        line = line.strip().strip("|")
        cells = [c.strip() for c in line.split("|")]
        rows.append(cells)
    return rows

def _add_markdown_table(doc: Document, table_lines):
    """Markdown表を Word 表に変換して追加"""
    rows = _parse_md_table_lines(table_lines)
    if not rows:
        return

    header = rows[0]
    body = rows[1:] if len(rows) > 1 else []

    # 列数を header に合わせる（不足行は空で埋める/超過は切る）
    ncols = len(header)
    def _fit(row):
        if len(row) < ncols:
            return row + [""] * (ncols - len(row))
        if len(row) > ncols:
            return row[:ncols]
        return row

    header = _fit(header)
    body = [_fit(r) for r in body]

    table = doc.add_table(rows=1, cols=ncols)
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER

    # ヘッダー
    for i, text in enumerate(header):
        cell = table.rows[0].cells[i]
        p = cell.paragraphs[0]
        p.text = text
        _apply_jp_font_to_paragraph(p, size_pt=11)

    # 本文
    for r in body:
        row_cells = table.add_row().cells
        for i, text in enumerate(r):
            cell = row_cells[i]
            p = cell.paragraphs[0]
            p.text = text
            _apply_jp_font_to_paragraph(p, size_pt=11)

    # 表の後に少しだけ間隔（空段落は作らず、次段落の余白で吸収したいが簡易に1段落）
    p = doc.add_paragraph("")
    _compact_paragraph(p, line_spacing=1.0, space_after_pt=4, space_before_pt=0)


def export_to_word(session: Session, company_code: int, proposal_text: str, phase: str):
    """
    Markdown形式の提案書をWord（.docx）形式に変換してStageにアップロード
    """

    now = datetime.now()
    filename = f"{company_code}.docx"
    stage_path = f"@GENERATED_PROPOSALS/{filename}"

    doc = Document()

    # タイトル
    title = doc.add_heading("成長戦略提案書", 0)
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    _apply_jp_font_to_paragraph(title, size_pt=18)

    # サブタイトル
    phase_name_map = {
        "phase1": "フェーズ1: 企業概要・分析",
        "phase2": "フェーズ2: 成長戦略・提案",
        "phase3": "フェーズ3: 効果試算・ロードマップ",
        "complete": "完全版（全フェーズ統合）",
    }
    subtitle = doc.add_paragraph(f"企業コード: {company_code} - {phase_name_map.get(phase, phase)}")
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    _compact_paragraph(subtitle, line_spacing=1.1, space_after_pt=2)
    _apply_jp_font_to_paragraph(subtitle, size_pt=14)

    # 日付
    date_para = doc.add_paragraph(f"作成日: {now.strftime('%Y年%m月%d日')}")
    date_para.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    _compact_paragraph(date_para, line_spacing=1.0, space_after_pt=8)
    _apply_jp_font_to_paragraph(date_para, size_pt=11)

    # ------------------------------------------------------------
    # Markdown → Word 変換
    #   - 空行で段落を作らない（ページ膨張防止）
    #   - Markdown表を Word表に変換
    #   - 文字化け対策でフォント適用
    #   - 行間は 1.15 を基本に（1.5は膨らみやすい）
    # ------------------------------------------------------------
    lines = proposal_text.splitlines()

    table_buffer = []
    in_table = False

    for raw in lines:
        line_raw = raw.rstrip("\n")
        stripped = line_raw.strip()

        # 1) 表行の収集
        if _is_markdown_table_row(line_raw):
            in_table = True
            table_buffer.append(line_raw)
            continue

        # 2) 表の終了検出：表行じゃなくなったら flush
        if in_table and not _is_markdown_table_row(line_raw):
            _add_markdown_table(doc, table_buffer)
            table_buffer.clear()
            in_table = False
            # ここで continue せず、この行も通常処理に回す

        # 3) 空行は段落を作らずスキップ（重要）
        if not stripped:
            continue

        # 4) Markdownヘッダー
        if stripped.startswith("# "):
            h = doc.add_heading(stripped[2:], level=1)
            _apply_jp_font_to_paragraph(h, size_pt=14)
            _compact_paragraph(h, line_spacing=1.1, space_before_pt=6, space_after_pt=3)
            continue
        if stripped.startswith("## "):
            h = doc.add_heading(stripped[3:], level=2)
            _apply_jp_font_to_paragraph(h, size_pt=13)
            _compact_paragraph(h, line_spacing=1.1, space_before_pt=5, space_after_pt=2)
            continue
        if stripped.startswith("### "):
            h = doc.add_heading(stripped[4:], level=3)
            _apply_jp_font_to_paragraph(h, size_pt=12)
            _compact_paragraph(h, line_spacing=1.1, space_before_pt=4, space_after_pt=2)
            continue
        if stripped.startswith("#### "):
            h = doc.add_heading(stripped[5:], level=4)
            _apply_jp_font_to_paragraph(h, size_pt=11)
            _compact_paragraph(h, line_spacing=1.1, space_before_pt=3, space_after_pt=1)
            continue

        # 5) 箇条書き
        if stripped.startswith("- ") or stripped.startswith("* "):
            p = doc.add_paragraph(stripped[2:], style="List Bullet")
            _apply_jp_font_to_paragraph(p, size_pt=11)
            _compact_paragraph(p, line_spacing=1.15, space_after_pt=0)
            continue

        # 6) 番号付き（1. ～ 99. まで対応）
        m = re.match(r"^(\d+)\.\s+(.*)$", stripped)
        if m:
            content = m.group(2)
            p = doc.add_paragraph(content, style="List Number")
            _apply_jp_font_to_paragraph(p, size_pt=11)
            _compact_paragraph(p, line_spacing=1.15, space_after_pt=0)
            continue

        # 7) 通常段落
        p = doc.add_paragraph(stripped)
        _apply_jp_font_to_paragraph(p, size_pt=11)
        _compact_paragraph(p, line_spacing=1.15, space_after_pt=2)

    # ループ終端で表が閉じていなければ flush
    if in_table and table_buffer:
        _add_markdown_table(doc, table_buffer)

    # 保存（バイナリ）
    buffer = BytesIO()
    doc.save(buffer)
    buffer.seek(0)
    docx_bytes = buffer.getvalue()

    file_size_kb = len(docx_bytes) / 1024

    local_path = f"/tmp/{filename}"
    with open(local_path, "wb") as f:
        f.write(docx_bytes)

    session.file.put(
        local_path,
        "@GENERATED_PROPOSALS/",
        auto_compress=False,
        overwrite=True
    )

    presigned_url_sql = f"""
        SELECT GET_PRESIGNED_URL(@GENERATED_PROPOSALS, '{filename}', 180) AS presigned_url
    """
    result = session.sql(presigned_url_sql).collect()
    presigned_url = result[0]["PRESIGNED_URL"] if result else None

    result_dict = {
        "file_path": stage_path,
        "presigned_url": presigned_url,
        "file_size_kb": round(file_size_kb, 2),
        "filename": filename,
    }

    return json.dumps(result_dict, ensure_ascii=False)
$$;

-- ================================================================
-- Step 3: カスタムツール2 - 業界動向調査関数
-- ================================================================
-- 注: 将来的に実装予定（現在は未実装）

-- ================================================================
-- Step 4: 動作確認
-- ================================================================

-- 【テスト1】 Word出力Stored Procedureの単体テスト
-- 注: 実行には約10-20秒かかる場合があります
CALL EXPORT_PROPOSAL_TO_WORD(
    12044,
    '# テスト提案書

## 企業概要

これはテスト提案書です。

### 基本情報
- 企業コード: 12044
- 業種: 総合建設業
- 所在地: 茨城県水戸市

### 財務状況
2023年度の売上高は前年比で増加しました。

## 成長戦略

以下の3つの戦略を提案します:

1. DX推進による業務効率化
2. GX対応による環境配慮型事業の拡大
3. 人材確保と育成の強化

以上です。',
    'phase1'
);

-- 結果の確認（期待される出力）
-- {
--   "file_path": "@GENERATED_PROPOSALS/12044_phase1_20250124_1430.docx",
--   "presigned_url": "https://...",
--   "file_size_kb": 156.42,
--   "filename": "12044_phase1_20250124_1430.docx"
-- }

-- 【テスト2】 業界動向調査関数の単体テスト
-- 注: 将来的に実装予定

-- 【テスト3】 Stage内のファイル確認
LIST @GENERATED_PROPOSALS;

-- 【テスト4】 生成されたWordファイルのダウンロードリンク取得
-- 注: {filename} を実際のファイル名に置き換えてください
-- SELECT GET_PRESIGNED_URL(@GENERATED_PROPOSALS, '12044_phase1_20250124_1430.docx', 604800) AS download_url;

-- ================================================================
-- Step 5: Cortex Agentへの統合
-- ================================================================

-- 【重要】 次のステップ:
-- 1. このファイル（09_create_custom_tools.sql）を実行
-- 2. 10_create_cortex_agent.sql を更新してカスタムツールを追加
-- 3. Cortex Agentを再作成（10番ファイル全体を実行）
-- 4. Snowsight UIまたはStreamlitでテスト

-- 【Cortex Agent更新内容】
-- 10_create_cortex_agent.sql に以下を追加:
--
-- tools セクション:
--   - ExportProposalToWord (function)
--
-- tool_resources セクション:
--   - ExportProposalToWord: FDUA_COMPETITION.PUBLIC.EXPORT_PROPOSAL_TO_WORD
--
-- instructions.orchestration セクション:
--   - フェーズ完成時にExportProposalToWordツールを使用

-- ================================================================
-- トラブルシューティング
-- ================================================================

-- 問題1: python-docxパッケージが見つからない
-- 対策: Snowflakeのパッケージリストを確認
-- SELECT * FROM INFORMATION_SCHEMA.PACKAGES WHERE PACKAGE_NAME LIKE '%docx%';
--
-- python-docxが利用できない場合:
-- - 関数を簡易版に変更（プレーンテキスト出力）
-- - または、Streamlit側で既存のdocx_writer.pyを使用

-- 問題2: PUT Files エラーが発生
-- 対策:
-- - session.sql("PUT ...")ではなくsession.file.put()を使用する
-- - overwrite=Trueを必ず指定する
-- - 参考: https://qiita.com/abe_masanori/items/e761dc033c2efbc00570

-- 問題3: JSON抽出が失敗
-- 対策:
-- - フォールバック処理が動作するか確認
-- - プロンプトでJSON形式を明示
-- - 正規表現パターンを調整

-- 問題4: Stage権限エラー
-- 対策:
-- GRANT READ, WRITE ON STAGE GENERATED_PROPOSALS TO ROLE ACCOUNTADMIN;

-- 問題5: GET_PRESIGNED_URLがエラー
-- 対策:
-- - Stageが@から始まることを確認
-- - ファイルが実際にStageにアップロードされているか確認（LIST @GENERATED_PROPOSALS）

-- ================================================================
-- メンテナンス
-- ================================================================

-- カスタムツールの削除（必要に応じて）
-- DROP PROCEDURE IF EXISTS EXPORT_PROPOSAL_TO_WORD(INTEGER, STRING, STRING);

-- 注: GENERATED_PROPOSALSは既存Stageなので削除しないこと
-- DROP STAGE IF EXISTS GENERATED_PROPOSALS;  -- 実行しないこと！

-- カスタムツールの再作成（Procedureを修正した場合）
-- 1. 上記のDROP文を実行
-- 2. このファイルのCREATE PROCEDURE文を再実行

-- ================================================================
-- 注意事項
-- ================================================================

-- 1. python-docxパッケージについて:
--    - Snowflake Python UDFで利用可能か確認が必要
--    - 利用できない場合は代替実装（プレーンテキスト出力）を検討

-- 2. Cortex Completeの制約:
--    - クエリ文字列内でシングルクォートのエスケープが必要
--    - JSON抽出が失敗する可能性があるため、フォールバック処理を実装
--    - タイムアウト設定が必要な場合がある

-- 3. Word出力の制約:
--    - Markdown → Word変換は簡易実装
--    - 複雑な書式（表、画像、複雑なレイアウト）は非対応
--    - 必要に応じて、Streamlit側で既存のdocx_writer.pyを使用

-- 4. ファイルサイズとコスト:
--    - Word出力: 1ファイルあたり100-500KB程度
--    - Stage容量: 無制限（従量課金）
--    - Cortex Complete: 実行ごとにクレジット消費

-- 5. セキュリティ:
--    - 事前署名付きURLは7日間有効
--    - URLを知っている人は誰でもダウンロード可能
--    - 機密情報を含む場合は、より短い有効期限を設定

-- 6. パフォーマンス:
--    - Word出力: 約10-20秒
--    - Cortex Agent実行時は、この時間が加算される

-- ================================================================
-- 次のステップ
-- ================================================================

-- 1. このファイル（09_create_custom_tools.sql）全体を実行
-- 2. 動作確認（テスト1）を実行
-- 3. 10_create_cortex_agent.sql を更新:
--    - tools セクションにExportProposalToWordツールを追加
--    - tool_resources セクションにリソース定義を追加
--    - orchestration セクションにツール使用の指示を追加
-- 4. Cortex Agentを再作成（10番ファイル全体を実行）
-- 5. Snowsight UIでCortex Agentをテスト:
--    - "企業コード12044の成長戦略提案書を作成してください"
--    - フェーズ1完成後、ExportProposalToWordツールが自動的に実行されることを確認
-- 6. Streamlitアプリからテスト（オプション）
-- 7. README.mdに新しいツールの説明を追加（オプション）

-- ================================================================
-- 参考リンク
-- ================================================================

-- Snowflake Cortex Complete:
-- https://docs.snowflake.com/en/sql-reference/functions/complete-snowflake-cortex

-- Snowflake Python UDF:
-- https://docs.snowflake.com/en/developer-guide/udf/python/udf-python

-- Snowflake Stage:
-- https://docs.snowflake.com/en/sql-reference/sql/create-stage

-- GET_PRESIGNED_URL:
-- https://docs.snowflake.com/en/sql-reference/functions/get_presigned_url                         