-- ================================================================
-- Semantic View作成 (Cortex Analyst用 - 正式構文)
-- ================================================================
-- CREATE SEMANTIC VIEW構文を使用して4つのビューを作成
-- 50列制限に対応するため、財務データを3つのビューに分割
-- ================================================================

USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;
USE WAREHOUSE WH_XSMALL;

-- ================================================================
-- Semantic View 1: 基本情報 + 損益計算書（P/L）
-- ================================================================
CREATE OR REPLACE SEMANTIC VIEW FINANCIAL_DATA_BASIC_AND_PL
  TABLES (
    fd AS FINANCIAL_DATA
      WITH SYNONYMS ('財務データ', 'financial data', '損益計算書', 'P/L')
      COMMENT = '財務データテーブル: 損益計算書を中心とした基本情報'
  )
  FACTS (
    -- P/L: 損益計算書の主要指標
    fd.revenue AS fd."売上高"
      WITH SYNONYMS ('売上', '収益', 'revenue', 'sales')
      COMMENT = '売上高',

    fd.cost_of_sales AS fd."売上原価"
      WITH SYNONYMS ('売上原価', '原価', 'cost of sales')
      COMMENT = '売上原価',

    fd.gross_profit AS fd."売上総利益"
      WITH SYNONYMS ('売上総利益', '粗利', 'gross profit')
      COMMENT = '売上総利益（売上高 - 売上原価）',

    fd.sg_and_a AS fd."販売費及び一般管理費"
      WITH SYNONYMS ('販管費', 'SG&A')
      COMMENT = '販売費及び一般管理費',

    fd.operating_profit AS fd."営業利益"
      WITH SYNONYMS ('営業利益', '営業益', 'operating profit')
      COMMENT = '営業利益（売上総利益 - 販管費）',

    fd.ordinary_profit AS fd."経常利益"
      WITH SYNONYMS ('経常利益', '経常益', 'ordinary profit')
      COMMENT = '経常利益（営業利益 + 営業外損益）',

    fd.pretax_profit AS fd."税金等調整前当期純利益"
      WITH SYNONYMS ('税引前利益', 'pretax profit')
      COMMENT = '税金等調整前当期純利益',

    fd.income_taxes AS fd."法人税等"
      WITH SYNONYMS ('法人税', '税金', 'income tax')
      COMMENT = '法人税等',

    fd.net_profit AS fd."当期純利益"
      WITH SYNONYMS ('当期純利益', '純利益', '最終利益', 'net profit')
      COMMENT = '当期純利益（税引後利益）',

    -- 営業外・特別損益
    fd.non_operating_income AS fd."営業外収益"
      WITH SYNONYMS ('営業外収益', 'non-operating income')
      COMMENT = '営業外収益',

    fd.non_operating_expenses AS fd."営業外費用"
      WITH SYNONYMS ('営業外費用', 'non-operating expenses')
      COMMENT = '営業外費用',

    fd.extraordinary_income AS fd."特別利益"
      WITH SYNONYMS ('特別利益', 'extraordinary income')
      COMMENT = '特別利益',

    fd.extraordinary_loss AS fd."特別損失"
      WITH SYNONYMS ('特別損失', 'extraordinary loss')
      COMMENT = '特別損失',

    -- 販管費の内訳
    fd.personnel_expenses AS fd."販売費及び一般管理費_人件費"
      WITH SYNONYMS ('人件費', 'personnel expenses')
      COMMENT = '販管費のうち人件費',

    fd.depreciation_sga AS fd."販売費及び一般管理費_減価償却費"
      WITH SYNONYMS ('減価償却費', 'depreciation')
      COMMENT = '販管費のうち減価償却費',

    fd.advertising_expenses AS fd."販売費及び一般管理費_広告宣伝費"
      WITH SYNONYMS ('広告宣伝費', '広告費', 'advertising')
      COMMENT = '販管費のうち広告宣伝費',

    fd.rd_expenses AS fd."販売費及び一般管理費_研究開発費"
      WITH SYNONYMS ('研究開発費', 'R&D', 'R&D費')
      COMMENT = '販管費のうち研究開発費',

    fd.rental_expenses AS fd."販売費及び一般管理費_賃借料"
      WITH SYNONYMS ('賃借料', '賃貸料', 'rental')
      COMMENT = '販管費のうち賃借料',

    -- 売上高の内訳
    fd.construction_revenue AS fd."売上高_完成工事高"
      WITH SYNONYMS ('完成工事高', 'construction revenue')
      COMMENT = '売上高のうち完成工事高',

    fd.real_estate_revenue AS fd."売上高_不動産事業売上高"
      WITH SYNONYMS ('不動産事業売上高', 'real estate revenue')
      COMMENT = '売上高のうち不動産事業売上高',

    fd.merchandise_revenue AS fd."売上高_商品売上高"
      WITH SYNONYMS ('商品売上高', 'merchandise revenue')
      COMMENT = '売上高のうち商品売上高',

    -- 売上原価の内訳
    fd.construction_cost AS fd."売上原価_完成工事原価"
      WITH SYNONYMS ('完成工事原価', 'construction cost')
      COMMENT = '売上原価のうち完成工事原価',

    fd.real_estate_cost AS fd."売上原価_不動産事業売上原価"
      WITH SYNONYMS ('不動産事業売上原価', 'real estate cost')
      COMMENT = '売上原価のうち不動産事業売上原価',

    fd.merchandise_cost AS fd."売上原価_商品売上原価"
      WITH SYNONYMS ('商品売上原価', 'merchandise cost')
      COMMENT = '売上原価のうち商品売上原価',

    -- 売上総利益の内訳
    fd.construction_gross_profit AS fd."売上総利益_完成工事総利益"
      WITH SYNONYMS ('完成工事総利益', 'construction gross profit')
      COMMENT = '売上総利益のうち完成工事総利益'
  )
  DIMENSIONS (
    -- 基本ディメンション（全ビューで共通、JOIN可能）
    PUBLIC fd.company_code AS fd."コード"
      WITH SYNONYMS ('企業コード', '会社コード', 'コード', 'code')
      COMMENT = '企業を識別する一意のコード',

    PUBLIC fd.location AS fd."本社所在地"
      WITH SYNONYMS ('本社所在地', '所在地', '地域', 'location')
      COMMENT = '企業の本社所在地（都道府県）',

    PUBLIC fd.industry AS fd."業種分類"
      WITH SYNONYMS ('業種分類', '業種', '産業', 'industry')
      COMMENT = '企業の業種分類',

    PUBLIC fd.market_classification AS fd."市場・商品区分"
      WITH SYNONYMS ('市場区分', '商品区分', 'market')
      COMMENT = '上場市場・商品区分',

    PUBLIC fd.fiscal_year AS fd.YEAR
      WITH SYNONYMS ('会計年度', '年度', '年', 'year')
      COMMENT = '会計年度（2023、2024、2025）',

    PUBLIC fd.employee_count AS fd."従業員数（連結）"
      WITH SYNONYMS ('従業員数', '社員数', 'employees')
      COMMENT = '連結従業員数',

    PUBLIC fd.capital_billion_yen AS fd."資本金（億円）"
      WITH SYNONYMS ('資本金', 'capital')
      COMMENT = '資本金（単位: 億円）'
  );

-- ================================================================
-- Semantic View 2: 貸借対照表（B/S）- 資産側
-- ================================================================
CREATE OR REPLACE SEMANTIC VIEW FINANCIAL_DATA_ASSETS
  TABLES (
    fd AS FINANCIAL_DATA
      WITH SYNONYMS ('財務データ', 'financial data', '貸借対照表', 'B/S', '資産')
      COMMENT = '財務データテーブル: 貸借対照表の資産側'
  )
  FACTS (
    -- B/S: 資産の主要指標
    fd.total_assets AS fd."総資産"
      WITH SYNONYMS ('総資産', '資産合計', 'total assets')
      COMMENT = '総資産',

    fd.current_assets AS fd."流動資産"
      WITH SYNONYMS ('流動資産', 'current assets')
      COMMENT = '流動資産（1年以内に現金化される資産）',

    fd.fixed_assets AS fd."固定資産"
      WITH SYNONYMS ('固定資産', 'fixed assets')
      COMMENT = '固定資産（1年を超えて保有される資産）',

    fd.tangible_fixed_assets AS fd."有形固定資産"
      WITH SYNONYMS ('有形固定資産', 'tangible assets')
      COMMENT = '有形固定資産（建物、土地、機械など）',

    fd.intangible_fixed_assets AS fd."無形固定資産"
      WITH SYNONYMS ('無形固定資産', 'intangible assets')
      COMMENT = '無形固定資産（ソフトウェア、のれんなど）',

    fd.investments_and_other_assets AS fd."投資その他の資産"
      WITH SYNONYMS ('投資その他の資産', 'investments')
      COMMENT = '投資その他の資産（投資有価証券、繰延税金資産など）',

    -- 流動資産の詳細
    fd.cash_and_deposits AS fd."流動資産_現金及び預金"
      WITH SYNONYMS ('現金及び預金', '現金', 'cash')
      COMMENT = '現金及び預金',

    fd.accounts_receivable AS fd."流動資産_受取手形及び売掛金"
      WITH SYNONYMS ('受取手形及び売掛金', '売掛金', 'receivables')
      COMMENT = '受取手形及び売掛金',

    fd.construction_receivables AS fd."流動資産_完成工事未収入金"
      WITH SYNONYMS ('完成工事未収入金', 'construction receivables')
      COMMENT = '完成工事未収入金',

    fd.work_in_progress AS fd."流動資産_未成工事支出金"
      WITH SYNONYMS ('未成工事支出金', 'work in progress')
      COMMENT = '未成工事支出金',

    fd.real_estate_for_sale AS fd."流動資産_販売用不動産"
      WITH SYNONYMS ('販売用不動産', 'real estate for sale')
      COMMENT = '販売用不動産',

    fd.merchandise_and_products AS fd."流動資産_商品及び製品"
      WITH SYNONYMS ('商品及び製品', '在庫', 'inventory')
      COMMENT = '商品及び製品',

    fd.raw_materials_and_supplies AS fd."流動資産_原材料及び貯蔵品"
      WITH SYNONYMS ('原材料及び貯蔵品', '原材料', 'raw materials')
      COMMENT = '原材料及び貯蔵品',

    -- 固定資産の詳細
    fd.buildings_and_structures AS fd."有形固定資産_建物及び構築物"
      WITH SYNONYMS ('建物及び構築物', '建物', 'buildings')
      COMMENT = '建物及び構築物',

    fd.machinery_and_vehicles AS fd."有形固定資産_機械装置及び車両運搬具"
      WITH SYNONYMS ('機械装置及び車両運搬具', '機械装置', 'machinery')
      COMMENT = '機械装置及び車両運搬具',

    fd.land AS fd."有形固定資産_土地"
      WITH SYNONYMS ('土地', 'land')
      COMMENT = '土地',

    fd.construction_in_progress AS fd."有形固定資産_建設仮勘定"
      WITH SYNONYMS ('建設仮勘定', 'construction in progress')
      COMMENT = '建設仮勘定',

    fd.leased_assets AS fd."有形固定資産_リース資産"
      WITH SYNONYMS ('リース資産', 'leased assets')
      COMMENT = 'リース資産',

    fd.software AS fd."無形固定資産_ソフトウェア"
      WITH SYNONYMS ('ソフトウェア', 'software')
      COMMENT = 'ソフトウェア',

    fd.goodwill AS fd."無形固定資産_のれん"
      WITH SYNONYMS ('のれん', 'goodwill')
      COMMENT = 'のれん',

    fd.investment_securities AS fd."投資その他の資産_投資有価証券"
      WITH SYNONYMS ('投資有価証券', '投資', 'investment securities')
      COMMENT = '投資有価証券',

    fd.deferred_tax_assets AS fd."投資その他の資産_繰延税金資産"
      WITH SYNONYMS ('繰延税金資産', 'deferred tax assets')
      COMMENT = '繰延税金資産'
  )
  DIMENSIONS (
    -- 基本ディメンション（JOIN用）
    PUBLIC fd.company_code AS fd."コード"
      WITH SYNONYMS ('企業コード', '会社コード', 'コード', 'code')
      COMMENT = '企業を識別する一意のコード',

    PUBLIC fd.location AS fd."本社所在地"
      WITH SYNONYMS ('本社所在地', '所在地', '地域', 'location')
      COMMENT = '企業の本社所在地（都道府県）',

    PUBLIC fd.industry AS fd."業種分類"
      WITH SYNONYMS ('業種分類', '業種', '産業', 'industry')
      COMMENT = '企業の業種分類',

    PUBLIC fd.fiscal_year AS fd.YEAR
      WITH SYNONYMS ('会計年度', '年度', '年', 'year')
      COMMENT = '会計年度（2023、2024、2025）'
  );

-- ================================================================
-- Semantic View 3: 貸借対照表（B/S）- 負債・純資産側 + キャッシュフロー
-- ================================================================
CREATE OR REPLACE SEMANTIC VIEW FINANCIAL_DATA_LIABILITIES_AND_EQUITY
  TABLES (
    fd AS FINANCIAL_DATA
      WITH SYNONYMS ('財務データ', 'financial data', '貸借対照表', 'B/S', '負債', '純資産', 'キャッシュフロー', 'C/F')
      COMMENT = '財務データテーブル: 貸借対照表の負債・純資産側とキャッシュフロー計算書'
  )
  FACTS (
    -- B/S: 負債・純資産の主要指標
    fd.total_liabilities AS fd."負債"
      WITH SYNONYMS ('負債合計', '負債', 'total liabilities')
      COMMENT = '負債合計',

    fd.current_liabilities AS fd."流動負債"
      WITH SYNONYMS ('流動負債', 'current liabilities')
      COMMENT = '流動負債（1年以内に返済する負債）',

    fd.fixed_liabilities AS fd."固定負債"
      WITH SYNONYMS ('固定負債', 'fixed liabilities')
      COMMENT = '固定負債（1年を超えて返済する負債）',

    fd.net_assets AS fd."純資産"
      WITH SYNONYMS ('純資産', '自己資本', 'net assets', 'equity')
      COMMENT = '純資産（資産 - 負債）',

    -- 流動負債の詳細
    fd.accounts_payable AS fd."流動負債_支払手形及び買掛金"
      WITH SYNONYMS ('支払手形及び買掛金', '買掛金', 'payables')
      COMMENT = '支払手形及び買掛金',

    fd.construction_payables AS fd."流動負債_工事未払金"
      WITH SYNONYMS ('工事未払金', 'construction payables')
      COMMENT = '工事未払金',

    fd.short_term_debt AS fd."流動負債_短期借入金"
      WITH SYNONYMS ('短期借入金', 'short-term debt')
      COMMENT = '短期借入金',

    fd.current_portion_long_term_debt AS fd."流動負債_1年内返済予定長期借入金"
      WITH SYNONYMS ('1年内返済予定長期借入金', 'current portion of long-term debt')
      COMMENT = '1年内返済予定長期借入金',

    fd.advances_received AS fd."流動負債_未成工事受入金"
      WITH SYNONYMS ('未成工事受入金', 'advances received')
      COMMENT = '未成工事受入金',

    fd.income_taxes_payable AS fd."流動負債_未払法人税等"
      WITH SYNONYMS ('未払法人税等', 'income taxes payable')
      COMMENT = '未払法人税等',

    fd.bonus_reserves AS fd."流動負債_賞与引当金"
      WITH SYNONYMS ('賞与引当金', 'bonus reserves')
      COMMENT = '賞与引当金',

    fd.construction_loss_reserves AS fd."流動負債_工事損失引当金"
      WITH SYNONYMS ('工事損失引当金', 'construction loss reserves')
      COMMENT = '工事損失引当金',

    -- 固定負債の詳細
    fd.long_term_debt AS fd."固定負債_長期借入金"
      WITH SYNONYMS ('長期借入金', 'long-term debt')
      COMMENT = '長期借入金',

    fd.bonds_payable AS fd."固定負債_社債"
      WITH SYNONYMS ('社債', 'bonds payable')
      COMMENT = '社債',

    fd.retirement_benefit_obligations AS fd."固定負債_退職給付に係る負債"
      WITH SYNONYMS ('退職給付に係る負債', '退職給付債務', 'retirement benefit obligations')
      COMMENT = '退職給付に係る負債',

    fd.lease_obligations AS fd."固定負債_リース債務"
      WITH SYNONYMS ('リース債務', 'lease obligations')
      COMMENT = 'リース債務',

    -- 純資産の内訳
    fd.capital_stock AS fd."純資産_資本金"
      WITH SYNONYMS ('資本金', 'capital stock')
      COMMENT = '資本金',

    fd.capital_surplus AS fd."純資産_資本剰余金"
      WITH SYNONYMS ('資本剰余金', 'capital surplus')
      COMMENT = '資本剰余金',

    fd.retained_earnings AS fd."純資産_利益剰余金"
      WITH SYNONYMS ('利益剰余金', 'retained earnings')
      COMMENT = '利益剰余金',

    fd.treasury_stock AS fd."純資産_自己株式"
      WITH SYNONYMS ('自己株式', 'treasury stock')
      COMMENT = '自己株式',

    fd.accumulated_other_comprehensive_income AS fd."純資産_その他の包括利益累計額"
      WITH SYNONYMS ('その他の包括利益累計額', 'accumulated other comprehensive income')
      COMMENT = 'その他の包括利益累計額',

    fd.non_controlling_interests AS fd."純資産_非支配株主持分"
      WITH SYNONYMS ('非支配株主持分', 'non-controlling interests')
      COMMENT = '非支配株主持分',

    -- C/F: キャッシュフロー計算書
    fd.operating_cf AS fd."営業活動によるキャッシュ・フロー"
      WITH SYNONYMS ('営業キャッシュフロー', '営業CF', 'operating cash flow')
      COMMENT = '営業活動によるキャッシュフロー',

    fd.investing_cf AS fd."投資活動によるキャッシュ・フロー"
      WITH SYNONYMS ('投資キャッシュフロー', '投資CF', 'investing cash flow')
      COMMENT = '投資活動によるキャッシュフロー',

    fd.financing_cf AS fd."財務活動によるキャッシュ・フロー"
      WITH SYNONYMS ('財務キャッシュフロー', '財務CF', 'financing cash flow')
      COMMENT = '財務活動によるキャッシュフロー',

    fd.cash_and_equivalents AS fd."現金及び現金同等物期末残高"
      WITH SYNONYMS ('現金及び現金同等物期末残高', '期末現金', 'cash and equivalents')
      COMMENT = '現金及び現金同等物期末残高'
  )
  DIMENSIONS (
    -- 基本ディメンション（JOIN用）
    PUBLIC fd.company_code AS fd."コード"
      WITH SYNONYMS ('企業コード', '会社コード', 'コード', 'code')
      COMMENT = '企業を識別する一意のコード',

    PUBLIC fd.location AS fd."本社所在地"
      WITH SYNONYMS ('本社所在地', '所在地', '地域', 'location')
      COMMENT = '企業の本社所在地（都道府県）',

    PUBLIC fd.industry AS fd."業種分類"
      WITH SYNONYMS ('業種分類', '業種', '産業', 'industry')
      COMMENT = '企業の業種分類',

    PUBLIC fd.fiscal_year AS fd.YEAR
      WITH SYNONYMS ('会計年度', '年度', '年', 'year')
      COMMENT = '会計年度（2023、2024、2025）'
  );

-- ================================================================
-- Semantic View 4: 有価証券報告書（FULL_TEXT含む）
-- ================================================================
CREATE OR REPLACE SEMANTIC VIEW SECURITIES_REPORTS_SEMANTIC
  TABLES (
    sr AS SECURITIES_REPORTS_TEXT
      WITH SYNONYMS ('有価証券報告書', 'securities reports', '報告書', 'レポート')
      COMMENT = '有価証券報告書のPDF全文とメタデータ'
  )
  FACTS (
    sr.full_text AS sr.FULL_TEXT
      WITH SYNONYMS ('全文', 'PDF全文', '本文', 'full text')
      COMMENT = '有価証券報告書のPDF全文（重要: Cortex Analyst検索対象）',

    sr.page_count AS sr.PAGE_COUNT
      WITH SYNONYMS ('ページ数', 'page count')
      COMMENT = '有価証券報告書のページ数',

    sr.character_count AS sr.CHARACTER_COUNT
      WITH SYNONYMS ('文字数', 'character count')
      COMMENT = '有価証券報告書の文字数（トークン数推定に使用: 1トークン ≈ 4文字）',

    sr.word_count AS sr.WORD_COUNT
      WITH SYNONYMS ('単語数', 'word count')
      COMMENT = '有価証券報告書の単語数'
  )
  DIMENSIONS (
    PUBLIC sr.company_code AS sr.COMPANY_CODE
      WITH SYNONYMS ('企業コード', '会社コード', 'コード', 'code')
      COMMENT = '企業を識別する一意のコード',

    PUBLIC sr.document_title AS sr.DOCUMENT_TITLE
      WITH SYNONYMS ('文書タイトル', 'タイトル', 'document title')
      COMMENT = '有価証券報告書のタイトル',

    PUBLIC sr.submission_date AS sr.SUBMISSION_DATE
      WITH SYNONYMS ('提出日', 'submission date')
      COMMENT = '有価証券報告書の提出日',

    PUBLIC sr.fiscal_period AS sr.FISCAL_PERIOD
      WITH SYNONYMS ('決算期', '会計期間', 'fiscal period')
      COMMENT = '決算期（例: 2025年3月期）',

    PUBLIC sr.fiscal_year AS sr.FISCAL_YEAR
      WITH SYNONYMS ('決算年度', '会計年度', '年度', 'fiscal year')
      COMMENT = '決算年度',

    PUBLIC sr.pdf_file_name AS sr.PDF_FILE_NAME
      WITH SYNONYMS ('PDFファイル名', 'ファイル名', 'PDF file name')
      COMMENT = 'PDFファイル名',

    PUBLIC sr.extraction_timestamp AS sr.EXTRACTION_TIMESTAMP
      WITH SYNONYMS ('抽出日時', '取得日時', 'extraction timestamp')
      COMMENT = 'PDF全文の抽出日時'
  );

-- ================================================================
-- 確認
-- ================================================================
-- ビューの作成を確認
SHOW VIEWS LIKE '%SEMANTIC%';
SHOW VIEWS LIKE 'FINANCIAL_DATA_%';

-- 各ビューの列数確認
SELECT COUNT(*) AS column_count, 'FINANCIAL_DATA_BASIC_AND_PL' AS view_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'PUBLIC'
  AND TABLE_NAME = 'FINANCIAL_DATA_BASIC_AND_PL'
UNION ALL
SELECT COUNT(*) AS column_count, 'FINANCIAL_DATA_ASSETS' AS view_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'PUBLIC'
  AND TABLE_NAME = 'FINANCIAL_DATA_ASSETS'
UNION ALL
SELECT COUNT(*) AS column_count, 'FINANCIAL_DATA_LIABILITIES_AND_EQUITY' AS view_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'PUBLIC'
  AND TABLE_NAME = 'FINANCIAL_DATA_LIABILITIES_AND_EQUITY'
UNION ALL
SELECT COUNT(*) AS column_count, 'SECURITIES_REPORTS_SEMANTIC' AS view_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'PUBLIC'
  AND TABLE_NAME = 'SECURITIES_REPORTS_SEMANTIC';

-- データ確認（P/L）
SELECT company_code, location, fiscal_year, revenue, operating_profit, net_profit
FROM FINANCIAL_DATA_BASIC_AND_PL
WHERE fiscal_year = 2025
LIMIT 3;

-- データ確認（資産）
SELECT company_code, fiscal_year, total_assets, current_assets, fixed_assets
FROM FINANCIAL_DATA_ASSETS
WHERE fiscal_year = 2025
LIMIT 3;

-- データ確認（負債・純資産）
SELECT company_code, fiscal_year, total_liabilities, net_assets, operating_cf
FROM FINANCIAL_DATA_LIABILITIES_AND_EQUITY
WHERE fiscal_year = 2025
LIMIT 3;

-- データ確認（有価証券報告書）
SELECT company_code, LENGTH(full_text) AS text_length, character_count, page_count
FROM SECURITIES_REPORTS_SEMANTIC
LIMIT 3;

