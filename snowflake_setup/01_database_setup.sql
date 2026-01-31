-- ================================================================
-- FDUA Competition - Database Setup
-- ================================================================
-- 第4回金融データ活用チャレンジ向けのベースラインソリューション
-- データベース、スキーマ、ロールの初期設定
-- ================================================================
use role accountadmin;
-- Database作成
CREATE DATABASE IF NOT EXISTS FDUA_COMPETITION
    COMMENT = '第4回金融データ活用チャレンジ - Baselineソリューション';

USE DATABASE FDUA_COMPETITION;

-- Schema作成
CREATE SCHEMA IF NOT EXISTS PUBLIC
    COMMENT = 'メインスキーマ: 財務データ、PDF、生成ログを管理';

USE SCHEMA PUBLIC;

-- ================================================================
-- 環境確認
-- ================================================================
SELECT CURRENT_DATABASE() AS DATABASE_NAME,
       CURRENT_SCHEMA() AS SCHEMA_NAME,
       CURRENT_WAREHOUSE() AS WAREHOUSE_NAME,
       CURRENT_ROLE() AS ROLE_NAME;
