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
-- 6. 有価証券報告書テキストテーブル（LAYOUT + Chunking対応）
-- ================================================================
CREATE OR REPLACE TABLE SECURITIES_REPORTS_CHUNKS (
  COMPANY_CODE NUMBER(38,0) NOT NULL COMMENT '企業コード',
  CHUNK_ID     NUMBER(38,0) NOT NULL COMMENT '企業内のチャンク連番(1..)',
  L1_TITLE     VARCHAR(200) NOT NULL COMMENT '章(L1) 見出し',
  L2_TITLE     VARCHAR(500) COMMENT '項目(L2) 見出し（無い場合NULL）',
  CHUNK_TEXT   VARCHAR(16777216) NOT NULL COMMENT 'チャンク本文',
  CHAR_COUNT   NUMBER(38,0) COMMENT 'チャンク文字数',
  START_POS    NUMBER(38,0) COMMENT '全文中の開始位置',
  END_POS      NUMBER(38,0) COMMENT '全文中の終了位置',
  DOCUMENT_TITLE  VARCHAR(500) COMMENT '文書タイトル',
  SUBMISSION_DATE DATE COMMENT '提出日',
  FISCAL_PERIOD   VARCHAR(100) COMMENT '決算期（例: 2025年3月期）',
  FISCAL_YEAR     NUMBER(38,0) COMMENT '決算年度（YYYY）',
  PAGE_COUNT      NUMBER(38,0) COMMENT 'ページ数',
  PDF_FILE_NAME   VARCHAR(200) COMMENT '元PDFファイル名',
  STAGE_PATH      VARCHAR(500) COMMENT 'Stageパス（@SECURITIES_REPORTS/...）',
  EXTRACTION_METHOD VARCHAR(100) DEFAULT 'AI_PARSE_DOCUMENT_LAYOUT' COMMENT '抽出方法',
  EXTRACTION_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT '抽出日時',

  PRIMARY KEY (COMPANY_CODE, CHUNK_ID)
);

ALTER TABLE SECURITIES_REPORTS_CHUNKS CLUSTER BY (COMPANY_CODE);

-- ================================================================
-- 6. 居住基本情報
-- ================================================================
CREATE TABLE "FDUA_COMPETITION"."PUBLIC"."PREFECTURE_RESIDENTIAL_BASIC_INFO" ( "調査年" VARCHAR , "地域" VARCHAR , "居住" VARCHAR , "総住宅数" VARCHAR , "居住世帯あり住宅数" VARCHAR , "居住世帯なし住宅数" VARCHAR , "一時現在者のみ住宅数" VARCHAR , "空き家数" VARCHAR , "建築中住宅数" VARCHAR , "専用住宅数" VARCHAR , "店舗その他の併用住宅数" VARCHAR , "持ち家数" VARCHAR , "借家数" VARCHAR , "公営・都市再生機構（ＵＲ）・公社の借家数" VARCHAR , "公営の借家数" VARCHAR , "都市再生機構（ＵＲ）・公社の借家数" VARCHAR , "民営借家数" VARCHAR , "給与住宅数" VARCHAR , "一戸建住宅数" VARCHAR , "一戸建住宅数（木造）" VARCHAR , "一戸建住宅数（非木造）" VARCHAR , "長屋建住宅数" VARCHAR , "長屋建住宅数（木造）" VARCHAR , "長屋建住宅数（非木造）" VARCHAR , "共同住宅数" VARCHAR , "共同住宅数（木造）" VARCHAR , "共同住宅数（非木造）" VARCHAR , "エレベーター付き共同住宅数（非木造）" VARCHAR , "高齢者対応型共同住宅数（非木造）" VARCHAR , "高齢者対応型共同住宅数" VARCHAR , "高齢者対応型共同住宅数のうちサービス付き高齢者住宅数" VARCHAR , "その他の建て方住宅数" VARCHAR , "木造住宅数" VARCHAR , "非木造住宅数" VARCHAR , "鉄筋・鉄骨コンクリート造住宅数" VARCHAR , "その他の構造住宅数" VARCHAR , "鉄骨造住宅数" VARCHAR , "1971～1980年建築住宅数" VARCHAR , "1981～1990年建築住宅数" VARCHAR , "1970年以前建築住宅数" VARCHAR , "1991～2000年建築住宅数" VARCHAR , "2001～2005年建築住宅数" VARCHAR , "2006～2010年建築住宅数" VARCHAR , "2011～2015年建築住宅数" VARCHAR , "2016～2020年建築住宅数" VARCHAR , "2021～2023年9月建築住宅数" VARCHAR , "着工居住用建築物数" VARCHAR , "着工新設住宅戸数" VARCHAR , "着工新設持家数" VARCHAR , "着工新設貸家数" VARCHAR , "着工新設貸家数（公営）" VARCHAR , "着工新設貸家数（都市再生機構）" NUMBER(38, 0) , "着工新設分譲住宅数" VARCHAR , "着工新設分譲住宅数（都市再生機構）" NUMBER(38, 0) , "着工新設給与住宅数" NUMBER(38, 0) , "着工新設持家・分譲住宅数" VARCHAR , "滅失住宅戸数" VARCHAR , "除却住宅戸数" VARCHAR , "災害住宅戸数" NUMBER(38, 0) , "居住室の畳数5.9畳以下住宅数" VARCHAR , "居住室の畳数6.0～11.9畳住宅数" VARCHAR , "居住室の畳数12.0～17.9畳住宅数" VARCHAR , "居住室の畳数18.0～23.9畳住宅数" VARCHAR , "居住室の畳数24.0～29.9畳住宅数" VARCHAR , "居住室の畳数30.0～35.9畳住宅数" VARCHAR , "居住室の畳数36.0～47.9畳住宅数" VARCHAR , "居住室の畳数48.0畳以上住宅数" VARCHAR , "1住宅当たり居住室数" VARCHAR , "1住宅当たり居住室数（持ち家）" VARCHAR , "1住宅当たり居住室数（借家）" VARCHAR , "1住宅当たり居住室の畳数" VARCHAR , "1住宅当たり居住室の畳数（持ち家）" VARCHAR , "1住宅当たり居住室の畳数（借家）" VARCHAR , "1住宅当たり延べ面積" VARCHAR , "1住宅当たり延べ面積（持ち家）" VARCHAR , "1住宅当たり延べ面積（借家）" VARCHAR , "1住宅当たり敷地面積" VARCHAR , "1住宅当たり敷地面積（一戸建）" VARCHAR , "1住宅当たり敷地面積（一戸建・持ち家）" VARCHAR , "1住宅当たり敷地面積（長屋建）" VARCHAR , "1住宅当たり敷地面積（長屋建・持ち家）" VARCHAR , "高齢者等用設備住宅数" VARCHAR , "高齢者等用設備住宅数（手すりがある）" VARCHAR , "高齢者等用設備住宅数（またぎやすい高さの浴槽）" VARCHAR , "高齢者等用設備住宅数（廊下など車いすで通行可能な幅）" VARCHAR , "高齢者等用設備住宅数（段差のない屋内）" VARCHAR , "高齢者等用設備住宅数（道路から玄関まで車いすで通行可能）" VARCHAR , "高齢者等用設備住宅数（浴室暖房乾燥機）" VARCHAR , "2019年以降における住宅の耐震改修工事をした持ち家総数" VARCHAR , "太陽熱を利用した温水機器等のある住宅数" VARCHAR , "太陽光を利用した発電機器のある住宅数" VARCHAR , "二重以上のサッシ又は複層ガラスの窓のある住宅数" VARCHAR , "オートロック式の共同住宅に住む主世帯数" VARCHAR , "着工居住用建築物床面積" VARCHAR , "着工新設住宅床面積" VARCHAR , "着工新設持家床面積" VARCHAR , "着工新設分譲住宅床面積" VARCHAR , "着工新設貸家床面積" VARCHAR , "着工新設給与住宅床面積" VARCHAR , "最寄りの保育所までの距離が100m未満の住宅に住んでいる主世帯数" VARCHAR , "最寄りの保育所までの距離が100～200m未満の住宅に住んでいる主世帯数" VARCHAR , "最寄りの保育所までの距離が200～500m未満の住宅に住んでいる主世帯数" VARCHAR , "最寄りの保育所までの距離が500～1000m未満の住宅に住んでいる主世帯数" VARCHAR , "最寄りの保育所までの距離が1000m以上の住宅に住んでいる主世帯数" VARCHAR , "最寄りの老人デイサービスセンターまでの距離が250m未満の住宅に住んでいる主世帯数" VARCHAR , "最寄りの老人デイサービスセンターまでの距離が250～500m未満の住宅に住んでいる主世帯数" VARCHAR , "最寄りの老人デイサービスセンターまでの距離が500～1000m未満の住宅に住んでいる主世帯数" VARCHAR , "最寄りの老人デイサービスセンターまでの距離が1000～2000m未満の住宅に住んでいる主世帯数" VARCHAR , "最寄りの老人デイサービスセンターまでの距離が2000m以上の住宅に住んでいる主世帯数" VARCHAR , "総世帯数" VARCHAR , "主世帯数（住宅・土地統計調査結果）" VARCHAR , "65歳以上の世帯員のいる主世帯数（住宅・土地統計調査結果）" VARCHAR , "住宅以外の建物に居住の世帯数" VARCHAR , "同居世帯数" VARCHAR , "総世帯人員" VARCHAR , "主世帯人員（住宅・土地統計調査結果）" VARCHAR , "住宅以外の建物に居住の世帯人員" VARCHAR , "同居世帯人員" VARCHAR , "1世帯当たり居住室数（主世帯）" VARCHAR , "1世帯当たり居住室数（持ち家・主世帯）" VARCHAR , "1世帯当たり居住室数（借家・主世帯）" VARCHAR , "1世帯当たり居住室数（同居世帯）" VARCHAR , "1世帯当たり畳数（主世帯）" VARCHAR , "1世帯当たり畳数（持ち家・主世帯）" VARCHAR , "1世帯当たり畳数（借家・主世帯）" VARCHAR , "1人当たり畳数（主世帯）" VARCHAR , "1人当たり畳数（持ち家・主世帯）" VARCHAR , "1人当たり畳数（借家・主世帯）" VARCHAR , "1世帯当たり畳数（同居世帯）" VARCHAR , "世帯１人当たり居住室の畳数（住宅以外の建物に居住の世帯）" VARCHAR , "最低居住面積水準以上の主世帯数" VARCHAR , "誘導居住面積水準以上の主世帯数" VARCHAR , "現住居以外の住宅所有主世帯数" VARCHAR , "現住居以外の所有住宅数（主世帯）" VARCHAR , "現住居以外の所有住宅数（主世帯）（親族居住用）" VARCHAR , "現住居以外の所有住宅数（主世帯）（二次的住宅・別荘用）（空き家）" VARCHAR , "現住居以外の所有住宅数（主世帯）（貸家用）" VARCHAR , "現住居敷地所有主世帯数" VARCHAR , "現住居敷地以外の宅地など所有主世帯数" VARCHAR , "現住居敷地以外の宅地など所有主世帯数（持ち家）" VARCHAR , "現住居敷地以外の宅地など所有主世帯数（借家）" VARCHAR , "現住居敷地以外の宅地など所有件数（主世帯）" VARCHAR , "現住居敷地以外の宅地など所有件数（主世帯）（持ち家）" VARCHAR , "現住居敷地以外の宅地など所有件数（主世帯）（借家）" VARCHAR , "3.3m2当たり家賃（民営賃貸住宅）" VARCHAR , "専用住宅の1畳当たり家賃" VARCHAR , "専用住宅の1畳当たり家賃（公営の借家）" VARCHAR , "専用住宅の1畳当たり家賃（都市再生機構（ＵＲ）・公社の借家）" VARCHAR , "専用住宅の1畳当たり家賃（民営借家）" VARCHAR , "専用住宅の1畳当たり家賃（給与住宅）" VARCHAR , "着工居住用建築物工事費予定額" VARCHAR , "発電電力量" VARCHAR , "電力需要量" VARCHAR , "ガソリン販売量" VARCHAR , "上水道給水人口" VARCHAR , "簡易水道給水人口" VARCHAR , "専用水道給水人口" VARCHAR , "総人口（非水洗化人口＋水洗化人口）" VARCHAR , "非水洗化人口" VARCHAR , "水洗化率（浄化槽人口）" VARCHAR , "し尿処理量（し尿＋浄化槽汚泥＋自家処理量）" VARCHAR , "ごみ計画収集人口" VARCHAR , "ごみ総排出量（総量）" VARCHAR , "ごみ総排出量（計画収集量）" VARCHAR , "ごみ総排出量（直接搬入量）" VARCHAR , "ごみ総排出量（自家処理量）" VARCHAR , "ごみ総排出量（集団回収量）" VARCHAR , "1人1日当たりの排出量" VARCHAR , "ごみ処理量（総量）" VARCHAR , "ごみ処理量（直接資源化）" VARCHAR , "中間処理後再生利用量" VARCHAR , "ごみのリサイクル率" VARCHAR , "ごみ最終処分量" VARCHAR , "最終処分場埋立容量" VARCHAR , "最終処分場残余容量" VARCHAR , "理容・美容所数" VARCHAR , "理容所数" VARCHAR , "美容所数" VARCHAR , "クリーニング業数" VARCHAR , "公衆浴場数" VARCHAR , "給油所数" VARCHAR , "道路実延長" VARCHAR , "道路実延長（高速道路を含む）" VARCHAR , "道路実延長（主要道路）" VARCHAR , "道路実延長（一般国道）" VARCHAR , "道路実延長（主要地方道）" VARCHAR , "道路実延長（一般都道府県道）" VARCHAR , "道路実延長（市町村道）" VARCHAR , "道路実延長（高速道路）" VARCHAR , "舗装道路実延長" VARCHAR , "舗装道路実延長（主要道路）" VARCHAR , "舗装道路実延長（一般国道）" VARCHAR , "舗装道路実延長（主要地方道）" VARCHAR , "舗装道路実延長（一般都道府県道）" VARCHAR , "舗装道路実延長（市町村道）" VARCHAR , "軽自動車等台数" VARCHAR , "二輪の小型自動車台数" VARCHAR , "原動機付自転車台数" VARCHAR , "原動機付自転車台数（50ｃｃ以下）" VARCHAR , "原動機付自転車台数（50ｃｃ超90ｃｃ以下）" VARCHAR , "原動機付自転車台数（90ｃｃ超）" VARCHAR , "原動機付自転車台数（ミニカー）" VARCHAR , "軽自動車及び小型特殊自動車台数" VARCHAR , "二輪車台数（側車付のものを含む）" VARCHAR , "三輪車台数" NUMBER(38, 0) , "家計を主に支える者が雇用者である主世帯数" VARCHAR , "家計を主に支える者が雇用者である主世帯数（通勤時間30分未満）" VARCHAR , "家計を主に支える者が雇用者である主世帯数（通勤時間30分～1時間未満）" VARCHAR , "家計を主に支える者が雇用者である主世帯数（通勤時間1時間～1時間30分未満）" VARCHAR , "家計を主に支える者が雇用者である主世帯数（通勤時間1時間30分以上）" VARCHAR , "郵便局数" VARCHAR , "電話加入数" VARCHAR , "電話加入数（住宅用）" VARCHAR , "公衆電話設置台数" VARCHAR , "携帯電話・PHS契約数" VARCHAR , "テレビ放送受信契約数" VARCHAR , "衛星放送受信契約数" VARCHAR , "ケーブルテレビ加入世帯数" VARCHAR , "ブロードバンドサービス契約数（3．9－4世代携帯電話アクセスサービス契約数を除く）" VARCHAR , "都市計画区域指定面積" VARCHAR , "市街化調整区域面積" VARCHAR , "市街化区域面積" VARCHAR , "用途地域面積" VARCHAR , "住居専用地域面積" VARCHAR , "住居地域面積" VARCHAR , "近隣商業地域面積" VARCHAR , "商業地域面積" VARCHAR , "準工業地域面積" VARCHAR , "工業地域面積" VARCHAR , "工業専用地域面積" VARCHAR , "商業・近隣商業地域面積" VARCHAR , "工業・準工業地域面積" VARCHAR , "都市公園数" VARCHAR , "街区公園数" VARCHAR , "近隣公園数" VARCHAR , "運動公園数" VARCHAR , "都市公園面積" VARCHAR , "街区公園面積" VARCHAR , "近隣公園面積" VARCHAR , "運動公園面積" VARCHAR , "緩衝緑地面積" VARCHAR , "都市緑地面積" VARCHAR , "緑道面積" VARCHAR );

-- ================================================================
-- 7. 居住社会生活情報
-- ================================================================
CREATE TABLE "FDUA_COMPETITION"."PUBLIC"."PREFECTURE_RESIDENTIAL_SOCIAL_LIFE_INFO" ( "調査年" VARCHAR , "地域" VARCHAR , "居住" VARCHAR , "着工新設住宅比率" NUMBER(38, 1) , "持ち家比率" VARCHAR , "借家比率" VARCHAR , "民営借家比率" VARCHAR , "一戸建住宅比率" VARCHAR , "長屋建住宅比率" VARCHAR , "共同住宅比率" VARCHAR , "空き家比率" VARCHAR , "着工新設持ち家比率" NUMBER(38, 1) , "着工新設貸家比率" NUMBER(38, 1) , "居住室数（1住宅当たり）" VARCHAR , "居住室数（1住宅当たり）（持ち家）" VARCHAR , "居住室数（1住宅当たり）（借家）" VARCHAR , "持ち家住宅の居住室の畳数（1住宅当たり）" VARCHAR , "借家住宅の居住室の畳数（1住宅当たり）" VARCHAR , "持ち家住宅の延べ面積（1住宅当たり）" VARCHAR , "借家住宅の延べ面積（1住宅当たり）" VARCHAR , "着工新設持ち家住宅の床面積（1住宅当たり）" NUMBER(38, 1) , "着工新設貸家住宅の床面積（1住宅当たり）" NUMBER(38, 1) , "持ち家住宅の畳数（1人当たり）" VARCHAR , "借家住宅の畳数（1人当たり）" VARCHAR , "最低居住面積水準以上世帯割合" VARCHAR , "家計を主に支える者が雇用者である主世帯比率（通勤時間1時間30分以上）（主世帯千世帯当たり）" VARCHAR , "民営賃貸住宅の家賃（1か月3.3m2当たり）" VARCHAR , "着工居住用建築物工事費予定額（床面積1m2当たり）" NUMBER(38, 1) , "ガソリン販売量" VARCHAR , "発電電力量" VARCHAR , "電力需要量" VARCHAR , "上水道給水人口比率（2012－）" VARCHAR , "し尿処理人口比率（2012－）" VARCHAR , "ごみのリサイクル率" VARCHAR , "ごみ埋立率" VARCHAR , "最終処分場残余容量" VARCHAR , "理容・美容所数（人口10万人当たり）" VARCHAR , "クリーニング所数（人口10万人当たり）" VARCHAR , "公衆浴場数（人口10万人当たり）" VARCHAR , "給油所数（道路実延長100km当たり）" VARCHAR , "郵便局数（可住地面積100km2当たり）" NUMBER(38, 2) , "電話加入数（人口千人当たり）" NUMBER(38, 1) , "住宅用電話加入数（人口千人当たり）" NUMBER(38, 1) , "公衆電話設置台数（人口千人当たり）" NUMBER(38, 2) , "携帯電話契約数（人口千人当たり）" VARCHAR , "道路実延長（総面積1km2当たり）" VARCHAR , "主要道路実延長（総面積1km2当たり）" VARCHAR , "主要道路舗装率" VARCHAR , "市町村道舗装率" VARCHAR , "市街化調整区域面積比率" VARCHAR , "住居専用地域面積比率" VARCHAR , "住居専用・住居地域面積比率" VARCHAR , "近隣商業地域面積比率" VARCHAR , "商業・近隣商業地域面積比率" VARCHAR , "工業・準工業地域面積比率" VARCHAR , "工業専用地域面積比率" VARCHAR , "都市公園面積（人口1人当たり）" VARCHAR , "都市公園数（可住地面積100km2当たり）" VARCHAR , "街区公園数（可住地面積100km2当たり）" VARCHAR , "近隣公園数（可住地面積100km2当たり）" VARCHAR , "運動公園数（可住地面積100km2当たり）" VARCHAR ); 

-- ================================================================
-- テーブル確認
-- ================================================================
SHOW TABLES;
