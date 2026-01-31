-- ================================================================
-- FDUA Competition - Stage Creation
-- ================================================================
-- PDF、生成物、一時ファイル用のStage定義
-- ================================================================

USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;

-- ================================================================
-- 1. 有価証券報告書PDF用Stage
-- ================================================================
CREATE OR REPLACE STAGE SECURITIES_REPORTS
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')  -- Snowflakeマネージド暗号化
    DIRECTORY = (ENABLE = TRUE)            -- Directory Table有効化（メタデータ管理）
    COMMENT = '有価証券報告書PDF格納用Stage（10社分）';

-- Directory Tableの更新（ファイルメタデータを取得）
ALTER STAGE SECURITIES_REPORTS REFRESH;

-- Stageの確認
LIST @SECURITIES_REPORTS;

-- ================================================================
-- 2. 生成された提案書(.docx)用Stage
-- ================================================================
CREATE OR REPLACE STAGE GENERATED_PROPOSALS
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = '生成された提案書（.docx）格納用Stage';

ALTER STAGE GENERATED_PROPOSALS REFRESH;

-- ================================================================
-- 3. プロンプトログ(.docx)用Stage
-- ================================================================
CREATE OR REPLACE STAGE PROMPT_LOGS_STAGE
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'プロンプトログ（.docx）格納用Stage';

ALTER STAGE PROMPT_LOGS_STAGE REFRESH;

-- ================================================================
-- 4. 検証プロセスレポート(.docx)用Stage
-- ================================================================
CREATE OR REPLACE STAGE VERIFICATION_REPORTS_STAGE
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = '検証プロセスレポート（.docx）格納用Stage';

ALTER STAGE VERIFICATION_REPORTS_STAGE REFRESH;

-- ================================================================
-- 5. 一時ファイル用Stage（アップロード・ダウンロード用）
-- ================================================================
CREATE OR REPLACE STAGE TEMP_FILES
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = '一時ファイル用Stage';

ALTER STAGE TEMP_FILES REFRESH;

-- ================================================================
-- Stage一覧確認
-- ================================================================
SHOW STAGES;
