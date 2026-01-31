-- ================================================================
-- FDUA Competition - Data Loading
-- ================================================================
-- CSVとPDFをSnowflakeにアップロード・ロード
-- ================================================================

USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;

-- ================================================================
-- 注意: PUTコマンドはSnowSQL CLI、Snowsight UI、またはPython Connector経由で実行
-- このファイルをWorksheetで実行する前に、以下のコマンドをローカルで実行してください
-- ================================================================

-- ================================================================
-- ステップ1: ローカルからSnowflakeへファイルアップロード（SnowSQL CLI）
-- ================================================================
-- 以下のコマンドをローカル端末で実行:
--
-- $ snowsql -a <account> -u <user>
--
-- snowsql> USE DATABASE FDUA_COMPETITION;
-- snowsql> USE SCHEMA PUBLIC;
--
-- # CSVアップロード（一時Stage）
-- snowsql> PUT file://data/financial_data.csv @~/staged AUTO_COMPRESS=FALSE;
--
-- # PDFアップロード（10社分）
-- snowsql> PUT file://data/securities_report/有価証券報告書（12044）.pdf @SECURITIES_REPORTS;
-- snowsql> PUT file://data/securities_report/有価証券報告書（71768）.pdf @SECURITIES_REPORTS;
-- snowsql> PUT file://data/securities_report/有価証券報告書（73617）.pdf @SECURITIES_REPORTS;
-- snowsql> PUT file://data/securities_report/有価証券報告書（99702）.pdf @SECURITIES_REPORTS;
-- snowsql> PUT file://data/securities_report/有価証券報告書（141634）.pdf @SECURITIES_REPORTS;
-- snowsql> PUT file://data/securities_report/有価証券報告書（184226）.pdf @SECURITIES_REPORTS;
-- snowsql> PUT file://data/securities_report/有価証券報告書（244359）.pdf @SECURITIES_REPORTS;
-- snowsql> PUT file://data/securities_report/有価証券報告書（292640）.pdf @SECURITIES_REPORTS;
-- snowsql> PUT file://data/securities_report/有価証券報告書（308582）.pdf @SECURITIES_REPORTS;
-- snowsql> PUT file://data/securities_report/有価証券報告書（325042）.pdf @SECURITIES_REPORTS;
--
-- または、Snowsight UIの「Load Data」機能を使用してアップロード

-- ================================================================
-- ステップ2: CSVデータをテーブルにロード（Worksheetで実行）
-- ================================================================

-- アップロードされたファイルを確認
LIST @~/staged;

-- FINANCIAL_DATAテーブルにロード
COPY INTO FINANCIAL_DATA
FROM @~/staged/financial_data.csv  -- 自動圧縮される場合は.gz
FILE_FORMAT = (
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    ENCODING = 'UTF8'
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
)
ON_ERROR = CONTINUE;  -- エラー行をスキップ

-- ================================================================
-- ステップ3: データロード確認
-- ================================================================

-- レコード数確認（30行: 10社 x 3年）
SELECT COUNT(*) AS TOTAL_ROWS FROM FINANCIAL_DATA;

-- 企業別レコード数確認
SELECT "コード",
       "本社所在地",
       "業種分類",
       COUNT(*) AS YEARS
FROM FINANCIAL_DATA
GROUP BY "コード", "本社所在地", "業種分類"
ORDER BY "コード";

-- 年度別レコード数確認
SELECT YEAR,
       COUNT(*) AS COMPANIES
FROM FINANCIAL_DATA
GROUP BY YEAR
ORDER BY YEAR;

-- ================================================================
-- ステップ4: PDFアップロード確認
-- ================================================================

-- アップロードされたPDFファイル一覧
LIST @SECURITIES_REPORTS;

-- ファイル数確認（10ファイルあるはず）
SELECT COUNT(*) AS PDF_COUNT
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- ================================================================
-- ステップ5: サンプルデータ確認
-- ================================================================

-- 企業コード12044（茨城あずま建設）の3年分データ
SELECT "コード",
       "本社所在地",
       "業種分類",
       YEAR,
       "売上高",
       "営業利益",
       "経常利益",
       "当期純利益",
       "総資産",
       "純資産"
FROM FINANCIAL_DATA
WHERE "コード" = 12044
ORDER BY YEAR;
