-- ================================================================
-- FDUA Competition - Table Creation
-- ================================================================
-- 財務データ、ログ、レポート用のテーブル定義
-- ================================================================

USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;

-- ================================================================
-- 1. 財務データテーブル (financial_data.csv)
-- ================================================================
CREATE OR REPLACE TABLE FINANCIAL_DATA (
    -- 基本情報
    "コード"  INTEGER COMMENT '企業コード',
    "本社所在地"  VARCHAR(100) COMMENT '本社所在地（都道府県）',
    "市場・商品区分"  VARCHAR(100) COMMENT '市場・商品区分',
    "従業員数（連結）"  INTEGER COMMENT '従業員数（連結）',
    "資本金（億円）"  FLOAT COMMENT '資本金（億円）',
    "業種分類"  VARCHAR(100) COMMENT '業種分類',
    YEAR INTEGER COMMENT '会計年度',

    -- 損益計算書（P/L）
    "売上高"  BIGINT COMMENT '売上高',
    "営業利益"  BIGINT COMMENT '営業利益',
    "経常利益"  BIGINT COMMENT '経常利益',
    "当期純利益"  BIGINT COMMENT '当期純利益',

    -- 貸借対照表（B/S）
    "総資産"  BIGINT COMMENT '総資産',
    "純資産"  BIGINT COMMENT '純資産',

    -- キャッシュフロー計算書（C/F）
    "営業活動によるキャッシュ・フロー"  BIGINT COMMENT '営業CF',
    "投資活動によるキャッシュ・フロー"  BIGINT COMMENT '投資CF',
    "財務活動によるキャッシュ・フロー"  BIGINT COMMENT '財務CF',
    "現金及び現金同等物期末残高"  BIGINT COMMENT '現金及び現金同等物期末残高',

    -- 固定負債
    "固定負債_退職給付に係る負債"  BIGINT COMMENT '固定負債: 退職給付に係る負債',
    "固定負債_資産除去債務"  BIGINT COMMENT '固定負債: 資産除去債務',
    "固定負債_長期借入金"  BIGINT COMMENT '固定負債: 長期借入金',
    "固定負債_社債"  BIGINT COMMENT '固定負債: 社債',
    "固定負債_リース債務"  BIGINT COMMENT '固定負債: リース債務',
    "固定負債"  BIGINT COMMENT '固定負債合計',
    "固定負債_その他"  BIGINT COMMENT '固定負債: その他',

    -- 営業外損益
    "営業外収益"  BIGINT COMMENT '営業外収益',
    "営業外費用"  BIGINT COMMENT '営業外費用',

    -- 税金
    "法人税等"  BIGINT COMMENT '法人税等',
    "税金等調整前当期純利益"  BIGINT COMMENT '税金等調整前当期純利益',

    -- 投資その他の資産
    "投資その他の資産_繰延税金資産"  BIGINT COMMENT '投資その他の資産: 繰延税金資産',
    "投資その他の資産_投資有価証券"  BIGINT COMMENT '投資その他の資産: 投資有価証券',
    "投資その他の資産_長期貸付金"  BIGINT COMMENT '投資その他の資産: 長期貸付金',
    "投資その他の資産_投資不動産"  BIGINT COMMENT '投資その他の資産: 投資不動産',
    "投資その他の資産"  BIGINT COMMENT '投資その他の資産合計',

    -- 有形固定資産
    "有形固定資産_機械装置及び車両運搬具"  BIGINT COMMENT '有形固定資産: 機械装置及び車両運搬具',
    "有形固定資産_リース資産"  BIGINT COMMENT '有形固定資産: リース資産',
    "有形固定資産_建物及び構築物"  BIGINT COMMENT '有形固定資産: 建物及び構築物',
    "有形固定資産_減価償却累計額"  BIGINT COMMENT '有形固定資産: 減価償却累計額',
    "有形固定資産_土地"  BIGINT COMMENT '有形固定資産: 土地',
    "有形固定資産_建設仮勘定"  BIGINT COMMENT '有形固定資産: 建設仮勘定',
    "有形固定資産_工具器具及び備品"  BIGINT COMMENT '有形固定資産: 工具器具及び備品',
    "有形固定資産"  BIGINT COMMENT '有形固定資産合計',

    -- 流動資産
    "流動資産_商品及び製品"  BIGINT COMMENT '流動資産: 商品及び製品',
    "流動資産_現金及び預金"  BIGINT COMMENT '流動資産: 現金及び預金',
    "流動資産_完成工事未収入金"  BIGINT COMMENT '流動資産: 完成工事未収入金',
    "流動資産_受取手形及び売掛金"  BIGINT COMMENT '流動資産: 受取手形及び売掛金',
    "流動資産_販売用不動産"  BIGINT COMMENT '流動資産: 販売用不動産',
    "流動資産_短期有価証券"  BIGINT COMMENT '流動資産: 短期有価証券',
    "流動資産_未成工事支出金"  BIGINT COMMENT '流動資産: 未成工事支出金',
    "流動資産_原材料及び貯蔵品"  BIGINT COMMENT '流動資産: 原材料及び貯蔵品',
    "流動資産_貸倒引当金"  BIGINT COMMENT '流動資産: 貸倒引当金',
    "流動資産"  BIGINT COMMENT '流動資産合計',

    -- 固定資産
    "固定資産"  BIGINT COMMENT '固定資産合計',

    -- 販売費及び一般管理費
    "販売費及び一般管理費_広告宣伝費"  BIGINT COMMENT '販売費及び一般管理費: 広告宣伝費',
    "販売費及び一般管理費_減価償却費"  BIGINT COMMENT '販売費及び一般管理費: 減価償却費',
    "販売費及び一般管理費_租税公課"  BIGINT COMMENT '販売費及び一般管理費: 租税公課',
    "販売費及び一般管理費_研究開発費"  BIGINT COMMENT '販売費及び一般管理費: 研究開発費',
    "販売費及び一般管理費_賃借料"  BIGINT COMMENT '販売費及び一般管理費: 賃借料',
    "販売費及び一般管理費_人件費"  BIGINT COMMENT '販売費及び一般管理費: 人件費',
    "販売費及び一般管理費_その他"  BIGINT COMMENT '販売費及び一般管理費: その他',
    "販売費及び一般管理費"  BIGINT COMMENT '販売費及び一般管理費合計',

    -- 流動負債
    "流動負債_未成工事受入金"  BIGINT COMMENT '流動負債: 未成工事受入金',
    "流動負債_未払法人税等"  BIGINT COMMENT '流動負債: 未払法人税等',
    "流動負債_工事未払金"  BIGINT COMMENT '流動負債: 工事未払金',
    "流動負債_賞与引当金"  BIGINT COMMENT '流動負債: 賞与引当金',
    "流動負債_短期借入金"  BIGINT COMMENT '流動負債: 短期借入金',
    "流動負債_支払手形及び買掛金"  BIGINT COMMENT '流動負債: 支払手形及び買掛金',
    "流動負債_製品保証引当金"  BIGINT COMMENT '流動負債: 製品保証引当金',
    "流動負債_1年内返済予定長期借入金"  BIGINT COMMENT '流動負債: 1年内返済予定長期借入金',
    "流動負債_工事損失引当金"  BIGINT COMMENT '流動負債: 工事損失引当金',
    "流動負債"  BIGINT COMMENT '流動負債合計',

    -- 負債
    "負債"  BIGINT COMMENT '負債合計',

    -- 売上高詳細
    "売上高_商品売上高"  BIGINT COMMENT '売上高: 商品売上高',
    "売上高_完成工事高"  BIGINT COMMENT '売上高: 完成工事高',
    "売上高_不動産事業売上高"  BIGINT COMMENT '売上高: 不動産事業売上高',

    -- 純資産
    "純資産_非支配株主持分"  BIGINT COMMENT '純資産: 非支配株主持分',
    "純資産_自己株式"  BIGINT COMMENT '純資産: 自己株式',
    "純資産_利益剰余金"  BIGINT COMMENT '純資産: 利益剰余金',
    "純資産_資本剰余金"  BIGINT COMMENT '純資産: 資本剰余金',
    "純資産_その他の包括利益累計額"  BIGINT COMMENT '純資産: その他の包括利益累計額',
    "純資産_資本金"  BIGINT COMMENT '純資産: 資本金',

    -- 売上原価
    "売上原価_完成工事原価"  BIGINT COMMENT '売上原価: 完成工事原価',
    "売上原価_不動産事業売上原価"  BIGINT COMMENT '売上原価: 不動産事業売上原価',
    "売上原価_商品売上原価"  BIGINT COMMENT '売上原価: 商品売上原価',
    "売上原価"  BIGINT COMMENT '売上原価合計',

    -- 特別損益
    "特別利益"  BIGINT COMMENT '特別利益',
    "特別損失"  BIGINT COMMENT '特別損失',

    -- 無形固定資産
    "無形固定資産_ソフトウェア"  BIGINT COMMENT '無形固定資産: ソフトウェア',
    "無形固定資産_のれん"  BIGINT COMMENT '無形固定資産: のれん',
    "無形固定資産"  BIGINT COMMENT '無形固定資産合計',

    -- 売上総利益
    "売上総利益_完成工事総利益"  BIGINT COMMENT '売上総利益: 完成工事総利益',
    "売上総利益"  BIGINT COMMENT '売上総利益合計',

    -- その他
    "その他・未分類"  BIGINT COMMENT 'その他・未分類'
) COMMENT = '10社 x 3年分の財務データ（2023-2025）';

-- インデックス（クラスタリングキー）の設定
ALTER TABLE FINANCIAL_DATA CLUSTER BY ("コード", YEAR);

-- ================================================================
-- 2. プロンプトログテーブル
-- ================================================================
CREATE OR REPLACE TABLE PROMPT_LOGS (
    RUN_ID VARCHAR(36) PRIMARY KEY COMMENT '実行ID（UUID）',
    COMPANY_CODE INTEGER COMMENT '企業コード',
    COMPANY_NAME VARCHAR(200) COMMENT '企業名',
    INDUSTRY VARCHAR(100) COMMENT '業種分類',
    LOCATION VARCHAR(100) COMMENT '本社所在地',

    -- 入力パラメータ
    PERSPECTIVE VARCHAR(100) COMMENT '観点プリセット（売上拡大/コスト削減等）',
    ADDITIONAL_DATA_USED BOOLEAN COMMENT '追加データ使用フラグ',
    BASELINE_VERSION VARCHAR(20) COMMENT 'Baselineバージョン',

    -- プロンプト
    SYSTEM_PROMPT TEXT COMMENT 'システムプロンプト',
    USER_PROMPT TEXT COMMENT 'ユーザープロンプト',

    -- LLM応答
    LLM_MODEL VARCHAR(50) COMMENT '使用LLMモデル',
    FACT_SHEET_JSON VARIANT COMMENT 'Fact Sheet（JSON）',
    PROPOSAL_TEXT TEXT COMMENT '提案書本文',

    -- 参照チャンク
    REFERENCED_PDF_CHUNKS VARIANT COMMENT '参照したPDFチャンク（JSON配列）',
    REFERENCED_FINANCIAL_DATA VARIANT COMMENT '参照した財務データ（JSON）',

    -- 検証結果
    VALIDATION_RESULT VARIANT COMMENT '検証結果（JSON）',

    -- メタデータ
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT '作成日時',
    EXECUTION_TIME_SECONDS FLOAT COMMENT '実行時間（秒）'
) COMMENT = 'プロンプトログ: 生成AIの入出力完全記録';

-- ================================================================
-- 3. 検証プロセスレポートテーブル
-- ================================================================
CREATE OR REPLACE TABLE VERIFICATION_REPORTS (
    RUN_ID VARCHAR(36) PRIMARY KEY COMMENT '実行ID（PROMPT_LOGSと紐付け）',
    COMPANY_CODE INTEGER COMMENT '企業コード',

    -- 検証結果サマリ
    TOTAL_CHECKS INTEGER COMMENT '検証項目総数',
    PASSED_CHECKS INTEGER COMMENT 'パスした項目数',
    FAILED_CHECKS INTEGER COMMENT '失敗した項目数',

    -- ルールベース検証
    NUMERICAL_CONSISTENCY_CHECK BOOLEAN COMMENT '数値整合性チェック結果',
    COVERAGE_CHECK BOOLEAN COMMENT 'カバレッジチェック結果（PDF引用数、データ指標数）',
    FORMAT_CHECK BOOLEAN COMMENT '形式チェック結果（章立て、必須項目）',

    -- LLM自己レビュー
    LLM_REVIEW_RESULT VARIANT COMMENT 'LLM自己レビュー結果（JSON）',

    -- 詳細検証ログ
    VERIFICATION_DETAILS VARIANT COMMENT '検証詳細（JSON配列）',

    -- 改善提案
    IMPROVEMENT_SUGGESTIONS TEXT COMMENT '次の改善ポイント',

    -- メタデータ
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT '作成日時',

    FOREIGN KEY (RUN_ID) REFERENCES PROMPT_LOGS(RUN_ID)
) COMMENT = '検証プロセスレポート: 品質チェック結果';

-- ================================================================
-- 4. 生成された提案書管理テーブル
-- ================================================================
CREATE OR REPLACE TABLE GENERATED_PROPOSALS (
    PROPOSAL_ID VARCHAR(36) PRIMARY KEY COMMENT '提案書ID（UUID）',
    RUN_ID VARCHAR(36) COMMENT '実行ID（PROMPT_LOGSと紐付け）',
    COMPANY_CODE INTEGER COMMENT '企業コード',

    -- 提案書メタデータ
    FILE_NAME VARCHAR(200) COMMENT 'ファイル名（[企業コード].docx）',
    CHARACTER_COUNT INTEGER COMMENT '文字数',
    PAGE_COUNT INTEGER COMMENT 'ページ数（推定）',

    -- 提案書本文（セクション別）
    SECTION_1_OVERVIEW TEXT COMMENT '企業概要・分析',
    SECTION_2_STRATEGY TEXT COMMENT '成長戦略、提案',
    SECTION_3_ROADMAP TEXT COMMENT '効果試算、ロードマップ',

    -- .docxファイル参照
    DOCX_STAGE_PATH VARCHAR(500) COMMENT 'Stageに保存された.docxファイルのパス',

    -- メタデータ
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT '作成日時',

    FOREIGN KEY (RUN_ID) REFERENCES PROMPT_LOGS(RUN_ID)
) COMMENT = '生成された提案書管理テーブル';

-- ================================================================
-- 5. 有価証券報告書テキストテーブル
-- ================================================================
CREATE OR REPLACE TABLE SECURITIES_REPORTS_TEXT (
    -- Primary Key
    COMPANY_CODE INTEGER PRIMARY KEY COMMENT '企業コード',

    -- PDF Content
    FULL_TEXT TEXT COMMENT 'PDF全文（pdfplumber抽出）',

    -- Metadata
    DOCUMENT_TITLE VARCHAR(500) COMMENT '文書タイトル',
    SUBMISSION_DATE DATE COMMENT '提出日',
    FISCAL_PERIOD VARCHAR(100) COMMENT '決算期（例: 2025年3月期）',
    FISCAL_YEAR INTEGER COMMENT '決算年度（YYYY）',

    -- Document Statistics
    PAGE_COUNT INTEGER COMMENT 'ページ数',
    CHARACTER_COUNT INTEGER COMMENT '文字数',
    WORD_COUNT INTEGER COMMENT '単語数（推定）',

    -- Source Reference
    PDF_FILE_NAME VARCHAR(200) COMMENT '元PDFファイル名',
    STAGE_PATH VARCHAR(500) COMMENT 'Stageパス（@SECURITIES_REPORTS/...）',

    -- Processing Metadata
    EXTRACTION_METHOD VARCHAR(50) DEFAULT 'pdfplumber' COMMENT '抽出方法',
    EXTRACTION_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT '抽出日時'

) COMMENT = '有価証券報告書テキストデータ（10社分、1行=1PDF）';

-- Clustering by company code for efficient lookup
ALTER TABLE SECURITIES_REPORTS_TEXT CLUSTER BY (COMPANY_CODE);

-- ================================================================
-- テーブル確認
-- ================================================================
SHOW TABLES;
