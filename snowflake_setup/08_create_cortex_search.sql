-- ================================================================
-- Cortex Search Service作成
-- ================================================================
-- 有価証券報告書テキストに対する高速セマンティック検索サービスを作成
-- 使い方: このファイル全体をSnowflake Web UIまたはSnowSQLで実行
-- ================================================================

USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;
USE WAREHOUSE WH_XSMALL;

-- ================================================================
-- Cortex Search Service: 有価証券報告書検索
-- ================================================================

-- 既存のサービスを削除（再作成する場合）
-- DROP CORTEX SEARCH SERVICE IF EXISTS SECURITIES_REPORTS_SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SECURITIES_REPORTS_SEARCH
ON FULL_TEXT
ATTRIBUTES COMPANY_CODE, DOCUMENT_TITLE, FISCAL_PERIOD, FISCAL_YEAR, SUBMISSION_DATE, PAGE_COUNT
WAREHOUSE = WH_XSMALL
TARGET_LAG = '1 minute'
AS (
    SELECT
        COMPANY_CODE,
        FULL_TEXT,
        DOCUMENT_TITLE,
        FISCAL_PERIOD,
        FISCAL_YEAR,
        SUBMISSION_DATE,
        PAGE_COUNT,
        CHARACTER_COUNT,
        WORD_COUNT,
        PDF_FILE_NAME
    FROM SECURITIES_REPORTS_TEXT
);

-- ================================================================
-- サービスの確認
-- ================================================================

-- Cortex Searchサービス一覧を表示
SHOW CORTEX SEARCH SERVICES;

-- サービスの詳細情報を取得
DESCRIBE CORTEX SEARCH SERVICE SECURITIES_REPORTS_SEARCH;

-- ================================================================
-- 使用例: Cortex Searchでの検索
-- ================================================================

-- 例1: 基本検索 - 「事業内容」に関する情報を検索
SELECT
    PARSE_JSON(
        SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
            'SECURITIES_REPORTS_SEARCH',
            '{
                "query": "事業内容と主要な取引先",
                "columns": ["COMPANY_CODE", "DOCUMENT_TITLE", "FISCAL_PERIOD"],
                "limit": 10
            }'
        )
    )['results'] as results;

-- 例2: フィルタ付き検索 - 特定企業の有価証券報告書を検索
SELECT
    PARSE_JSON(
        SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
            'SECURITIES_REPORTS_SEARCH',
            '{
                "query": "リスク情報",
                "columns": ["COMPANY_CODE", "DOCUMENT_TITLE", "FISCAL_PERIOD"],
                "filter": {"@eq": {"COMPANY_CODE": 12044}},
                "limit": 10
            }'
        )
    )['results'] as results;

-- 例3: 複数条件フィルタ - 決算期で絞り込み
SELECT
    PARSE_JSON(
        SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
            'SECURITIES_REPORTS_SEARCH',
            '{
                "query": "研究開発活動",
                "columns": ["COMPANY_CODE", "FISCAL_PERIOD"],
                "filter": {"@eq": {"FISCAL_YEAR": 2025}},
                "limit": 10
            }'
        )
    )['results'] as results;

-- 例4: 結果を見やすく展開
WITH search_results AS (
    SELECT
        PARSE_JSON(
            SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
                'SECURITIES_REPORTS_SEARCH',
                '{
                    "query": "従業員の状況",
                    "columns": ["COMPANY_CODE", "DOCUMENT_TITLE", "FISCAL_PERIOD"],
                    "limit": 5
                }'
            )
        )['results'] as results
)
SELECT
    result.value:COMPANY_CODE::INT AS company_code,
    result.value:DOCUMENT_TITLE::STRING AS document_title,
    result.value:FISCAL_PERIOD::STRING AS fiscal_period,
    result.value['@search_score']::FLOAT AS relevance_score
FROM search_results,
LATERAL FLATTEN(input => results) result
ORDER BY relevance_score DESC;

-- 例5: 企業コードのリストでフィルタ（@in演算子）
WITH search_results AS (
    SELECT
        PARSE_JSON(
            SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
                'SECURITIES_REPORTS_SEARCH',
                '{
                    "query": "競争環境と市場シェア",
                    "columns": ["COMPANY_CODE", "FISCAL_PERIOD"],
                    "filter": {"@eq": {"COMPANY_CODE": 12044}},
                    "limit": 10
                }'
            )
        )['results'] as results
)
SELECT
    result.value:COMPANY_CODE::INT AS company_code,
    result.value:FISCAL_PERIOD::STRING AS fiscal_period,
    result.value['@search_score']::FLOAT AS relevance_score
FROM search_results,
LATERAL FLATTEN(input => results) result
ORDER BY relevance_score DESC;

-- 例6: マッチしたテキストスニペットを取得
WITH search_results AS (
    SELECT
        PARSE_JSON(
            SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
                'SECURITIES_REPORTS_SEARCH',
                '{
                    "query": "DXやデジタル化への取り組み",
                    "columns": ["COMPANY_CODE", "DOCUMENT_TITLE", "FULL_TEXT"],
                    "limit": 5
                }'
            )
        )['results'] as results
)
SELECT
    result.value:COMPANY_CODE::INT AS company_code,
    result.value:DOCUMENT_TITLE::STRING AS document_title,
    -- マッチしたテキストの一部を表示（最初の500文字）
    LEFT(result.value:FULL_TEXT::STRING, 500) AS matched_snippet,
    result.value['@search_score']::FLOAT AS relevance_score
FROM search_results,
LATERAL FLATTEN(input => results) result
ORDER BY relevance_score DESC;

-- ================================================================
-- 注意事項
-- ================================================================
-- 1. TARGET_LAG: データ更新後、検索可能になるまでの遅延時間
--    - '1 minute': リアルタイム性重視（コスト高）
--    - '1 hour' or '1 day': バッチ処理向け（コスト低）
--
-- 2. WAREHOUSE: 検索実行時に使用するウェアハウス
--    - WH_XSMALLで十分（10社程度）
--    - データ量が増えたらWH_SMALLに変更
--
-- 3. ATTRIBUTES: フィルタリング可能なカラム
--    - 数値、文字列、日付型をサポート
--    - FULL_TEXTカラムはATTRIBUTESに含めない
--
-- 4. 検索クエリの言語: 日本語対応
--    - セマンティック検索: 意味的に類似したテキストを取得
--    - キーワード検索ではない
--
-- 5. スコアリング: 0.0〜1.0の関連度スコア
--    - 高いほど検索クエリとの関連性が高い
--
-- 6. コスト: Cortex Searchはクレジットを消費
--    - 検索実行ごとにクレジットが発生
--    - インデックス更新にもクレジットが発生

-- ================================================================
-- メンテナンス
-- ================================================================

-- サービスの一時停止（コスト削減）
ALTER CORTEX SEARCH SERVICE SECURITIES_REPORTS_SEARCH SUSPEND;

-- サービスの再開
ALTER CORTEX SEARCH SERVICE SECURITIES_REPORTS_SEARCH RESUME;

-- サービスの削除
-- DROP CORTEX SEARCH SERVICE SECURITIES_REPORTS_SEARCH;

-- インデックス再構築（データ不整合時）
-- ALTER CORTEX SEARCH SERVICE SECURITIES_REPORTS_SEARCH REFRESH;
