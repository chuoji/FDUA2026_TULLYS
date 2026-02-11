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
-- Semantic View 5: 有価証券報告書（チャンク単位）
CREATE OR REPLACE SEMANTIC VIEW SECURITIES_REPORTS_SEMANTIC_CHUNKS
  TABLES (
    sc AS SECURITIES_REPORTS_CHUNKS_ARRANGE
      WITH SYNONYMS ('有価証券報告書', 'securities reports', '報告書', 'レポート', 'チャンク', 'chunks')
      COMMENT = '有価証券報告書を章(L1)/項目(L2)単位で分割したチャンク本文とメタデータ'
  )
  FACTS (
    /* ★検索の主対象：L1+L2+本文を結合した列（あなたが作った列） */
    sc.chunk_text_arrange AS sc.CHUNK_TEXT_ARRANGE
      WITH SYNONYMS ('本文', 'チャンク本文', 'セクション本文', '結合本文', 'full text', 'chunk text')
      COMMENT = 'L1/L2見出しとチャンク本文を結合したテキスト（重要: Cortex Analyst検索対象）',

    sc.char_count AS sc.CHAR_COUNT
      WITH SYNONYMS ('文字数', 'char count', 'character count')
      COMMENT = 'チャンク文字数（トークン数推定: 1トークン ≈ 4文字）',

    sc.page_count AS sc.PAGE_COUNT
      WITH SYNONYMS ('ページ数', 'page count')
      COMMENT = '元PDFのページ数'
  )
  DIMENSIONS (
    PUBLIC sc.company_code AS sc.COMPANY_CODE
      WITH SYNONYMS ('企業コード', '会社コード', 'コード', 'code')
      COMMENT = '企業を識別するコード',

    PUBLIC sc.chunk_id AS sc.CHUNK_ID
      WITH SYNONYMS ('チャンクID', 'chunk id', '連番')
      COMMENT = '企業内のチャンク連番(1..)',

    PUBLIC sc.start_pos AS sc.START_POS
      WITH SYNONYMS ('開始位置', 'start', 'start position')
      COMMENT = '全文中の開始位置（参考）',

    PUBLIC sc.end_pos AS sc.END_POS
      WITH SYNONYMS ('終了位置', 'end', 'end position')
      COMMENT = '全文中の終了位置（参考）',

    PUBLIC sc.document_title AS sc.DOCUMENT_TITLE
      WITH SYNONYMS ('文書タイトル', 'タイトル', 'document title')
      COMMENT = '有価証券報告書のタイトル',

    PUBLIC sc.submission_date AS sc.SUBMISSION_DATE
      WITH SYNONYMS ('提出日', 'submission date')
      COMMENT = '有価証券報告書の提出日',

    PUBLIC sc.fiscal_period AS sc.FISCAL_PERIOD
      WITH SYNONYMS ('決算期', '会計期間', 'fiscal period')
      COMMENT = '決算期（例: 2025年3月期）',

    PUBLIC sc.fiscal_year AS sc.FISCAL_YEAR
      WITH SYNONYMS ('決算年度', '会計年度', '年度', 'fiscal year')
      COMMENT = '決算年度（YYYY）',

    PUBLIC sc.pdf_file_name AS sc.PDF_FILE_NAME
      WITH SYNONYMS ('PDFファイル名', 'ファイル名', 'PDF file name')
      COMMENT = '元PDFファイル名',

    PUBLIC sc.stage_path AS sc.STAGE_PATH
      WITH SYNONYMS ('ステージパス', 'stage path')
      COMMENT = 'Stageパス（@SECURITIES_REPORTS/...）',

    PUBLIC sc.extraction_timestamp AS sc.EXTRACTION_TIMESTAMP
      WITH SYNONYMS ('抽出日時', '取得日時', 'extraction timestamp')
      COMMENT = '抽出日時'
  );
  
-- ================================================================
-- Semantic View 6: 居住基本情報
-- ================================================================
CREATE OR REPLACE SEMANTIC VIEW PREF_RES_BASIC_PROPOSAL_SEMANTIC
  TABLES (
    pr AS FDUA_COMPETITION.PUBLIC.PREFECTURE_RESIDENTIAL_BASIC_INFO
      WITH SYNONYMS (
        '都道府県 居住 基本情報 統合',
        '住宅ストック',
        '建築インフラ提案',
        'regional housing and infrastructure',
        'proposal evidence'
      )
      COMMENT = '建築・インフラ企業の地域提案書作成の根拠として使う統合セマンティックビュー（住宅ストック/着工/居住水準/生活インフラ/都市機能）'
  )

  FACTS (
    -- =========================================================
    -- 1) 住宅ストック（更新・空き家・住宅類型）
    -- =========================================================
    pr."総住宅数" AS "総住宅数"
      WITH SYNONYMS ('住宅ストック', 'total dwellings', 'housing stock')
      COMMENT = '総住宅数',

    pr."空き家数" AS "空き家数"
      WITH SYNONYMS ('空き家', 'vacant houses', 'vacancy', 'ストック課題', 'リノベ需要')
      COMMENT = '空き家数',

    pr."持ち家数" AS "持ち家数"
      WITH SYNONYMS ('持ち家', 'owner-occupied', 'owned housing')
      COMMENT = '持ち家数',

    pr."借家数" AS "借家数"
      WITH SYNONYMS ('借家', 'rental housing', 'rented')
      COMMENT = '借家数',

    pr."民営借家数" AS "民営借家数"
      WITH SYNONYMS ('民営借家', 'private rental', '民間賃貸')
      COMMENT = '民営借家数',

    pr."公営の借家数" AS "公営の借家数"
      WITH SYNONYMS ('公営住宅', 'public rental', 'municipal housing')
      COMMENT = '公営の借家数',

    pr."給与住宅数" AS "給与住宅数"
      WITH SYNONYMS ('給与住宅', 'company housing', 'employer housing')
      COMMENT = '給与住宅数',

    pr."一戸建住宅数" AS "一戸建住宅数"
      WITH SYNONYMS ('一戸建', 'detached houses', '戸建て')
      COMMENT = '一戸建住宅数',

    pr."共同住宅数" AS "共同住宅数"
      WITH SYNONYMS ('共同住宅', '集合住宅', 'apartments', 'multi-family')
      COMMENT = '共同住宅数',

    pr."エレベーター付き共同住宅数（非木造）" AS "エレベーター付き共同住宅数（非木造）"
      WITH SYNONYMS ('エレベーター', 'EV', 'elevator', 'バリアフリー')
      COMMENT = 'エレベーター付き共同住宅数（非木造）',

    pr."高齢者対応型共同住宅数" AS "高齢者対応型共同住宅数"
      WITH SYNONYMS ('高齢者対応', 'elderly-friendly', 'バリアフリー住宅')
      COMMENT = '高齢者対応型共同住宅数',

    pr."高齢者対応型共同住宅数のうちサービス付き高齢者住宅数" AS "高齢者対応型共同住宅数のうちサービス付き高齢者住宅数"
      WITH SYNONYMS ('サ高住', 'サービス付き高齢者住宅', 'senior housing')
      COMMENT = '高齢者対応型共同住宅数のうちサービス付き高齢者住宅数',

    -- =========================================================
    -- 2) 建築年代（老朽化・更新投資の示唆）
    -- =========================================================
    pr."1970年以前建築住宅数" AS "1970年以前建築住宅数"
      WITH SYNONYMS ('老朽化', '築古', 'pre-1970', 'aging housing')
      COMMENT = '1970年以前建築住宅数',

    pr."1971～1980年建築住宅数" AS "1971～1980年建築住宅数"
      WITH SYNONYMS ('1970年代', 'aging housing', 'renovation')
      COMMENT = '1971～1980年建築住宅数',

    pr."1981～1990年建築住宅数" AS "1981～1990年建築住宅数"
      WITH SYNONYMS ('1980年代', 'stock', 'renovation')
      COMMENT = '1981～1990年建築住宅数',

    pr."1991～2000年建築住宅数" AS "1991～2000年建築住宅数"
      WITH SYNONYMS ('1990年代', 'stock')
      COMMENT = '1991～2000年建築住宅数',

    pr."2016～2020年建築住宅数" AS "2016～2020年建築住宅数"
      WITH SYNONYMS ('新しい住宅', 'newer stock')
      COMMENT = '2016～2020年建築住宅数',

    pr."2021～2023年9月建築住宅数" AS "2021～2023年9月建築住宅数"
      WITH SYNONYMS ('直近建築', 'newest stock', 'recent construction')
      COMMENT = '2021～2023年9月建築住宅数',

    -- =========================================================
    -- 3) 着工・滅失（需要/供給・更新の示唆）
    -- =========================================================
    pr."着工居住用建築物数" AS "着工居住用建築物数"
      WITH SYNONYMS ('着工', 'construction starts', 'building starts', '供給')
      COMMENT = '着工居住用建築物数',

    pr."着工新設住宅戸数" AS "着工新設住宅戸数"
      WITH SYNONYMS ('新設住宅', 'housing starts', 'new housing units')
      COMMENT = '着工新設住宅戸数',

    pr."着工新設持家数" AS "着工新設持家数"
      WITH SYNONYMS ('持家新設', 'owner-occupied starts')
      COMMENT = '着工新設持家数',

    pr."着工新設貸家数" AS "着工新設貸家数"
      WITH SYNONYMS ('賃貸新設', 'rental starts')
      COMMENT = '着工新設貸家数',

    pr."着工新設分譲住宅数" AS "着工新設分譲住宅数"
      WITH SYNONYMS ('分譲', 'for-sale condos', 'condominium starts')
      COMMENT = '着工新設分譲住宅数',

    pr."滅失住宅戸数" AS "滅失住宅戸数"
      WITH SYNONYMS ('滅失', 'demolition', 'loss of housing', '更新')
      COMMENT = '滅失住宅戸数',

    pr."除却住宅戸数" AS "除却住宅戸数"
      WITH SYNONYMS ('除却', 'demolition', 'removal')
      COMMENT = '除却住宅戸数',

    -- =========================================================
    -- 4) 居住水準（広さ・面積：住環境の質）
    -- =========================================================
    pr."1住宅当たり居住室数" AS "1住宅当たり居住室数"
      WITH SYNONYMS ('居住室数', 'rooms per dwelling', '住環境')
      COMMENT = '1住宅当たり居住室数',

    pr."1住宅当たり居住室の畳数" AS "1住宅当たり居住室の畳数"
      WITH SYNONYMS ('畳数', 'tatami', '居住の広さ')
      COMMENT = '1住宅当たり居住室の畳数',

    pr."1住宅当たり延べ面積" AS "1住宅当たり延べ面積"
      WITH SYNONYMS ('延べ面積', 'floor area', 'm2', 'sqm')
      COMMENT = '1住宅当たり延べ面積',

    pr."最低居住面積水準以上の主世帯数" AS "最低居住面積水準以上の主世帯数"
      WITH SYNONYMS ('最低居住面積水準', 'minimum living area standard')
      COMMENT = '最低居住面積水準以上の主世帯数',

    pr."誘導居住面積水準以上の主世帯数" AS "誘導居住面積水準以上の主世帯数"
      WITH SYNONYMS ('誘導居住面積水準', 'recommended living area standard')
      COMMENT = '誘導居住面積水準以上の主世帯数',

    -- =========================================================
    -- 5) 省エネ・創エネ・耐震（改修/設備更新の示唆）
    -- =========================================================
    pr."太陽光を利用した発電機器のある住宅数" AS "太陽光を利用した発電機器のある住宅数"
      WITH SYNONYMS ('太陽光', 'PV', 'solar power', 'photovoltaic', '脱炭素')
      COMMENT = '太陽光を利用した発電機器のある住宅数',

    pr."太陽熱を利用した温水機器等のある住宅数" AS "太陽熱を利用した温水機器等のある住宅数"
      WITH SYNONYMS ('太陽熱', 'solar thermal', '温水機器')
      COMMENT = '太陽熱を利用した温水機器等のある住宅数',

    pr."二重以上のサッシ又は複層ガラスの窓のある住宅数" AS "二重以上のサッシ又は複層ガラスの窓のある住宅数"
      WITH SYNONYMS ('二重サッシ', '複層ガラス', 'double glazing', '省エネ改修')
      COMMENT = '二重以上のサッシ又は複層ガラスの窓のある住宅数',

    pr."2019年以降における住宅の耐震改修工事をした持ち家総数" AS "2019年以降における住宅の耐震改修工事をした持ち家総数"
      WITH SYNONYMS ('耐震改修', 'seismic retrofit', '防災', 'レジリエンス')
      COMMENT = '2019年以降における住宅の耐震改修工事をした持ち家総数',

    pr."オートロック式の共同住宅に住む主世帯数" AS "オートロック式の共同住宅に住む主世帯数"
      WITH SYNONYMS ('オートロック', 'security', '防犯')
      COMMENT = 'オートロック式の共同住宅に住む主世帯数',

    -- =========================================================
    -- 6) エネルギー・水道・廃棄物（インフラ維持管理の示唆）
    -- =========================================================
    pr."発電電力量" AS "発電電力量"
      WITH SYNONYMS ('発電', 'electricity generation', '供給')
      COMMENT = '発電電力量',

    pr."電力需要量" AS "電力需要量"
      WITH SYNONYMS ('電力需要', 'electricity demand', '需要')
      COMMENT = '電力需要量',

    pr."上水道給水人口" AS "上水道給水人口"
      WITH SYNONYMS ('上水道', 'water supply', '給水人口')
      COMMENT = '上水道給水人口',

    pr."非水洗化人口" AS "非水洗化人口"
      WITH SYNONYMS ('非水洗', 'sanitation gap', '衛生')
      COMMENT = '非水洗化人口',

    pr."水洗化率（浄化槽人口）" AS "水洗化率（浄化槽人口）"
      WITH SYNONYMS ('水洗化率', '浄化槽', 'sanitation rate')
      COMMENT = '水洗化率（浄化槽人口）',

    pr."ごみのリサイクル率" AS "ごみのリサイクル率"
      WITH SYNONYMS ('リサイクル率', 'recycling rate', '循環')
      COMMENT = 'ごみのリサイクル率',

    pr."最終処分場残余容量" AS "最終処分場残余容量"
      WITH SYNONYMS ('残余容量', 'remaining capacity', 'landfill capacity')
      COMMENT = '最終処分場残余容量',

    -- =========================================================
    -- 7) 道路・交通（舗装/密度：維持更新の示唆）
    -- =========================================================
    pr."道路実延長" AS "道路実延長"
      WITH SYNONYMS ('道路延長', 'road length', '道路ネットワーク')
      COMMENT = '道路実延長',

    pr."舗装道路実延長" AS "舗装道路実延長"
      WITH SYNONYMS ('舗装', 'paved roads', '維持管理')
      COMMENT = '舗装道路実延長',

    pr."軽自動車等台数" AS "軽自動車等台数"
      WITH SYNONYMS ('軽自動車', 'kei cars', '交通需要')
      COMMENT = '軽自動車等台数',

    pr."原動機付自転車台数" AS "原動機付自転車台数"
      WITH SYNONYMS ('原付', 'moped', '二輪')
      COMMENT = '原動機付自転車台数',

    -- =========================================================
    -- 8) 通信（地域の接続性・防災通信）
    -- =========================================================
    pr."携帯電話・PHS契約数" AS "携帯電話・PHS契約数"
      WITH SYNONYMS ('携帯契約', 'mobile subscriptions', '通信需要')
      COMMENT = '携帯電話・PHS契約数',

    pr."ブロードバンドサービス契約数（3．9－4世代携帯電話アクセスサービス契約数を除く）" AS "ブロードバンドサービス契約数（3．9－4世代携帯電話アクセスサービス契約数を除く）"
      WITH SYNONYMS ('ブロードバンド', 'broadband', 'internet', 'デジタル基盤')
      COMMENT = 'ブロードバンドサービス契約数（3．9－4世代携帯電話アクセスサービス契約数を除く）',

    pr."公衆電話設置台数" AS "公衆電話設置台数"
      WITH SYNONYMS ('公衆電話', 'disaster communication', '防災通信')
      COMMENT = '公衆電話設置台数',

    -- =========================================================
    -- 9) 都市計画・公園（都市機能・住環境）
    -- =========================================================
    pr."用途地域面積" AS "用途地域面積"
      WITH SYNONYMS ('用途地域', 'zoning', 'land use')
      COMMENT = '用途地域面積',

    pr."市街化区域面積" AS "市街化区域面積"
      WITH SYNONYMS ('市街化区域', 'urbanized area')
      COMMENT = '市街化区域面積',

    pr."市街化調整区域面積" AS "市街化調整区域面積"
      WITH SYNONYMS ('市街化調整区域', 'urbanization control', '開発制約')
      COMMENT = '市街化調整区域面積',

    pr."都市公園数" AS "都市公園数"
      WITH SYNONYMS ('都市公園', 'parks', 'urban parks')
      COMMENT = '都市公園数',

    pr."都市公園面積" AS "都市公園面積"
      WITH SYNONYMS ('公園面積', 'park area', 'green space')
      COMMENT = '都市公園面積'
  )

  DIMENSIONS (
    pr."調査年" AS "調査年"
      WITH SYNONYMS ('年', '年度', 'survey year', 'year', '時点')
      COMMENT = '調査年',

    pr."地域" AS "地域"
      WITH SYNONYMS ('都道府県', 'prefecture', 'region', 'area', '自治体')
      COMMENT = '地域（都道府県など）'

  );

-- ================================================================
-- Semantic View 7: 居住社会生活情報
-- ================================================================
CREATE OR REPLACE SEMANTIC VIEW PREF_RES_SOCIAL_LIFE_PROPOSAL_SEMANTIC
  TABLES (
    pr AS FDUA_COMPETITION.PUBLIC.PREFECTURE_RESIDENTIAL_SOCIAL_LIFE_INFO
      WITH SYNONYMS (
        '都道府県 居住 社会生活 統合',
        '地域インフラ',
        '建築インフラ提案',
        'proposal evidence',
        'regional infrastructure indicators',
        'housing and infrastructure'
      )
      COMMENT = '建築・インフラ企業の地域提案書作成の根拠として使う統合セマンティックビュー（住宅/インフラ/都市機能/生活利便の横断指標）'
  )

  FACTS (
    -- =========================================================
    -- 1) 住宅市場・構成（需要/供給の示唆）
    -- =========================================================
    pr."着工新設住宅比率" AS "着工新設住宅比率"
      WITH SYNONYMS ('着工', '新設住宅', 'housing starts', 'construction', '供給')
      COMMENT = '着工新設住宅比率',

    pr."着工新設持ち家比率" AS "着工新設持ち家比率"
      WITH SYNONYMS ('新設持ち家', 'owner-occupied starts', '分譲', '持家新設')
      COMMENT = '着工新設持ち家比率',

    pr."着工新設貸家比率" AS "着工新設貸家比率"
      WITH SYNONYMS ('新設貸家', 'rental starts', '賃貸供給', '貸家新設')
      COMMENT = '着工新設貸家比率',

    pr."持ち家比率" AS "持ち家比率"
      WITH SYNONYMS ('持ち家', 'owner-occupied', 'ownership rate', '資産形成')
      COMMENT = '持ち家比率',

    pr."借家比率" AS "借家比率"
      WITH SYNONYMS ('借家', '賃貸', 'rental rate', '賃貸需要')
      COMMENT = '借家比率',

    pr."民営借家比率" AS "民営借家比率"
      WITH SYNONYMS ('民営借家', 'private rental', '民間賃貸', '賃貸市場')
      COMMENT = '民営借家比率',

    pr."一戸建住宅比率" AS "一戸建住宅比率"
      WITH SYNONYMS ('一戸建', 'detached house', '戸建て', '低層住宅')
      COMMENT = '一戸建住宅比率',

    pr."長屋建住宅比率" AS "長屋建住宅比率"
      WITH SYNONYMS ('長屋', 'row house', 'terraced house')
      COMMENT = '長屋建住宅比率',

    pr."共同住宅比率" AS "共同住宅比率"
      WITH SYNONYMS ('共同住宅', '集合住宅', 'apartment', 'multi-family', '中高層')
      COMMENT = '共同住宅比率',

    pr."空き家比率" AS "空き家比率"
      WITH SYNONYMS ('空き家', 'vacancy rate', '遊休', 'ストック課題', 'リノベ需要')
      COMMENT = '空き家比率',

    -- =========================================================
    -- 2) 居住水準（住まいの質 / 改修・更新の示唆）
    -- =========================================================
    pr."居住室数（1住宅当たり）" AS "居住室数（1住宅当たり）"
      WITH SYNONYMS ('居住室数', 'rooms', 'rooms per dwelling', '居住の広さ')
      COMMENT = '居住室数（1住宅当たり）',

    pr."居住室数（1住宅当たり）（持ち家）" AS "居住室数（1住宅当たり）（持ち家）"
      WITH SYNONYMS ('持ち家', 'rooms owner-occupied')
      COMMENT = '居住室数（1住宅当たり）（持ち家）',

    pr."居住室数（1住宅当たり）（借家）" AS "居住室数（1住宅当たり）（借家）"
      WITH SYNONYMS ('借家', 'rooms rental')
      COMMENT = '居住室数（1住宅当たり）（借家）',

    pr."持ち家住宅の居住室の畳数（1住宅当たり）" AS "持ち家住宅の居住室の畳数（1住宅当たり）"
      WITH SYNONYMS ('畳', 'tatami', 'floor area', '住宅の広さ')
      COMMENT = '持ち家住宅の居住室の畳数（1住宅当たり）',

    pr."借家住宅の居住室の畳数（1住宅当たり）" AS "借家住宅の居住室の畳数（1住宅当たり）"
      WITH SYNONYMS ('畳', 'tatami', 'rental tatami')
      COMMENT = '借家住宅の居住室の畳数（1住宅当たり）',

    pr."持ち家住宅の延べ面積（1住宅当たり）" AS "持ち家住宅の延べ面積（1住宅当たり）"
      WITH SYNONYMS ('延べ面積', 'floor area', 'm2', 'sqm')
      COMMENT = '持ち家住宅の延べ面積（1住宅当たり）',

    pr."借家住宅の延べ面積（1住宅当たり）" AS "借家住宅の延べ面積（1住宅当たり）"
      WITH SYNONYMS ('延べ面積', 'floor area', 'rental floor area')
      COMMENT = '借家住宅の延べ面積（1住宅当たり）',

    pr."着工新設持ち家住宅の床面積（1住宅当たり）" AS "着工新設持ち家住宅の床面積（1住宅当たり）"
      WITH SYNONYMS ('床面積', 'new owner-occupied', '新設床面積')
      COMMENT = '着工新設持ち家住宅の床面積（1住宅当たり）',

    pr."着工新設貸家住宅の床面積（1住宅当たり）" AS "着工新設貸家住宅の床面積（1住宅当たり）"
      WITH SYNONYMS ('床面積', 'new rental', '新設床面積')
      COMMENT = '着工新設貸家住宅の床面積（1住宅当たり）',

    pr."持ち家住宅の畳数（1人当たり）" AS "持ち家住宅の畳数（1人当たり）"
      WITH SYNONYMS ('1人当たり', 'per capita', '居住余裕', 'tatami per person')
      COMMENT = '持ち家住宅の畳数（1人当たり）',

    pr."借家住宅の畳数（1人当たり）" AS "借家住宅の畳数（1人当たり）"
      WITH SYNONYMS ('1人当たり', 'per capita', 'tatami per person rental')
      COMMENT = '借家住宅の畳数（1人当たり）',

    pr."最低居住面積水準以上世帯割合" AS "最低居住面積水準以上世帯割合"
      WITH SYNONYMS ('最低居住面積水準', 'minimum living area standard', '居住水準')
      COMMENT = '最低居住面積水準以上世帯割合',

    pr."家計を主に支える者が雇用者である主世帯比率（通勤時間1時間30分以上）（主世帯千世帯当たり）" AS "家計を主に支える者が雇用者である主世帯比率（通勤時間1時間30分以上）（主世帯千世帯当たり）"
      WITH SYNONYMS ('通勤', '長時間通勤', 'commute', 'over 90 minutes', '交通課題')
      COMMENT = '家計を主に支える者が雇用者である主世帯比率（通勤時間1時間30分以上）（主世帯千世帯当たり）',

    pr."民営賃貸住宅の家賃（1か月3.3m2当たり）" AS "民営賃貸住宅の家賃（1か月3.3m2当たり）"
      WITH SYNONYMS ('家賃', 'rent', 'private rental rent', 'コスト', '3.3m2')
      COMMENT = '民営賃貸住宅の家賃（1か月3.3m2当たり）',

    pr."着工居住用建築物工事費予定額（床面積1m2当たり）" AS "着工居住用建築物工事費予定額（床面積1m2当たり）"
      WITH SYNONYMS ('工事費', '建築費', 'construction cost', 'cost per m2', '単価')
      COMMENT = '着工居住用建築物工事費予定額（床面積1m2当たり）',

    -- =========================================================
    -- 3) エネルギー（需給/脱炭素/設備更新の示唆）
    -- =========================================================
    pr."ガソリン販売量" AS "ガソリン販売量"
      WITH SYNONYMS ('ガソリン', '燃料', 'fuel', 'gasoline sales', '交通需要')
      COMMENT = 'ガソリン販売量',

    pr."発電電力量" AS "発電電力量"
      WITH SYNONYMS ('発電', 'electricity generation', 'generated electricity', '供給')
      COMMENT = '発電電力量',

    pr."電力需要量" AS "電力需要量"
      WITH SYNONYMS ('電力需要', 'power demand', 'electricity demand', '需要')
      COMMENT = '電力需要量',

    -- =========================================================
    -- 4) 水道・衛生（更新/耐災害/維持管理の示唆）
    -- =========================================================
    pr."上水道給水人口比率（2012－）" AS "上水道給水人口比率（2012－）"
      WITH SYNONYMS ('上水道', '水道', 'water supply rate', '給水', 'インフラ維持')
      COMMENT = '上水道給水人口比率（2012－）',

    pr."し尿処理人口比率（2012－）" AS "し尿処理人口比率（2012－）"
      WITH SYNONYMS ('し尿処理', '衛生', 'sanitation', 'treatment rate', '下水代替')
      COMMENT = 'し尿処理人口比率（2012－）',

    -- =========================================================
    -- 5) 廃棄物・最終処分（処理能力/循環/施設更新の示唆）
    -- =========================================================
    pr."ごみのリサイクル率" AS "ごみのリサイクル率"
      WITH SYNONYMS ('リサイクル', 'recycling rate', '循環', '資源化')
      COMMENT = 'ごみのリサイクル率',

    pr."ごみ埋立率" AS "ごみ埋立率"
      WITH SYNONYMS ('埋立', 'landfill rate', '最終処分', '処分依存')
      COMMENT = 'ごみ埋立率',

    pr."最終処分場残余容量" AS "最終処分場残余容量"
      WITH SYNONYMS ('残余容量', 'remaining capacity', 'landfill capacity', '逼迫度')
      COMMENT = '最終処分場残余容量',

    -- =========================================================
    -- 6) 生活利便施設（地域サービスの厚み）
    -- =========================================================
    pr."理容・美容所数（人口10万人当たり）" AS "理容・美容所数（人口10万人当たり）"
      WITH SYNONYMS ('理容', '美容', 'hair salon', 'barber', 'サービス密度')
      COMMENT = '理容・美容所数（人口10万人当たり）',

    pr."クリーニング所数（人口10万人当たり）" AS "クリーニング所数（人口10万人当たり）"
      WITH SYNONYMS ('クリーニング', 'dry cleaning', 'サービス密度')
      COMMENT = 'クリーニング所数（人口10万人当たり）',

    pr."公衆浴場数（人口10万人当たり）" AS "公衆浴場数（人口10万人当たり）"
      WITH SYNONYMS ('公衆浴場', '銭湯', 'public bath', '生活インフラ')
      COMMENT = '公衆浴場数（人口10万人当たり）',

    pr."給油所数（道路実延長100km当たり）" AS "給油所数（道路実延長100km当たり）"
      WITH SYNONYMS ('給油所', 'gas station', '道路100km当たり', '交通サービス')
      COMMENT = '給油所数（道路実延長100km当たり）',

    pr."郵便局数（可住地面積100km2当たり）" AS "郵便局数（可住地面積100km2当たり）"
      WITH SYNONYMS ('郵便局', 'post office', '地域サービス', '可住地')
      COMMENT = '郵便局数（可住地面積100km2当たり）',

    -- =========================================================
    -- 7) 通信（デジタル基盤・地域の接続性）
    -- =========================================================
    pr."電話加入数（人口千人当たり）" AS "電話加入数（人口千人当たり）"
      WITH SYNONYMS ('固定電話', 'telephone subscriptions', 'per 1000', '通信基盤')
      COMMENT = '電話加入数（人口千人当たり）',

    pr."住宅用電話加入数（人口千人当たり）" AS "住宅用電話加入数（人口千人当たり）"
      WITH SYNONYMS ('住宅用電話', 'residential fixed line', '通信基盤')
      COMMENT = '住宅用電話加入数（人口千人当たり）',

    pr."公衆電話設置台数（人口千人当たり）" AS "公衆電話設置台数（人口千人当たり）"
      WITH SYNONYMS ('公衆電話', 'phone booths', '災害時通信', '防災通信')
      COMMENT = '公衆電話設置台数（人口千人当たり）',

    pr."携帯電話契約数（人口千人当たり）" AS "携帯電話契約数（人口千人当たり）"
      WITH SYNONYMS ('携帯電話', 'mobile subscriptions', 'スマホ', '通信需要')
      COMMENT = '携帯電話契約数（人口千人当たり）',

    -- =========================================================
    -- 8) 道路（維持更新・舗装率・ネットワーク密度）
    -- =========================================================
    pr."道路実延長（総面積1km2当たり）" AS "道路実延長（総面積1km2当たり）"
      WITH SYNONYMS ('道路延長', 'road length', 'per km2', '道路密度', 'インフラ老朽化')
      COMMENT = '道路実延長（総面積1km2当たり）',

    pr."主要道路実延長（総面積1km2当たり）" AS "主要道路実延長（総面積1km2当たり）"
      WITH SYNONYMS ('主要道路', 'major roads', 'per km2', '幹線道路')
      COMMENT = '主要道路実延長（総面積1km2当たり）',

    pr."主要道路舗装率" AS "主要道路舗装率"
      WITH SYNONYMS ('舗装率', 'paving rate', '補修', '維持管理')
      COMMENT = '主要道路舗装率',

    pr."市町村道舗装率" AS "市町村道舗装率"
      WITH SYNONYMS ('市町村道', 'municipal roads', '舗装率', '維持管理')
      COMMENT = '市町村道舗装率',

    -- =========================================================
    -- 9) 都市計画（用途地域）・公園（都市機能）
    -- =========================================================
    pr."市街化調整区域面積比率" AS "市街化調整区域面積比率"
      WITH SYNONYMS ('市街化調整区域', 'urbanization control', '開発制約', 'スプロール抑制')
      COMMENT = '市街化調整区域面積比率',

    pr."住居専用地域面積比率" AS "住居専用地域面積比率"
      WITH SYNONYMS ('住居専用', 'exclusive residential zone', '住宅地')
      COMMENT = '住居専用地域面積比率',

    pr."住居専用・住居地域面積比率" AS "住居専用・住居地域面積比率"
      WITH SYNONYMS ('住居地域', 'residential zones', '住宅地比率')
      COMMENT = '住居専用・住居地域面積比率',

    pr."近隣商業地域面積比率" AS "近隣商業地域面積比率"
      WITH SYNONYMS ('近隣商業', 'neighborhood commercial', '生活圏商業')
      COMMENT = '近隣商業地域面積比率',

    pr."商業・近隣商業地域面積比率" AS "商業・近隣商業地域面積比率"
      WITH SYNONYMS ('商業地域', 'commercial zones', '中心市街地')
      COMMENT = '商業・近隣商業地域面積比率',

    pr."工業・準工業地域面積比率" AS "工業・準工業地域面積比率"
      WITH SYNONYMS ('工業地域', '準工業地域', 'industrial zones', '産業立地')
      COMMENT = '工業・準工業地域面積比率',

    pr."工業専用地域面積比率" AS "工業専用地域面積比率"
      WITH SYNONYMS ('工業専用', 'exclusive industrial', '工業団地')
      COMMENT = '工業専用地域面積比率',

    pr."都市公園面積（人口1人当たり）" AS "都市公園面積（人口1人当たり）"
      WITH SYNONYMS ('都市公園', 'park area', 'per capita', '緑地', '住環境')
      COMMENT = '都市公園面積（人口1人当たり）',

    pr."都市公園数（可住地面積100km2当たり）" AS "都市公園数（可住地面積100km2当たり）"
      WITH SYNONYMS ('都市公園数', 'urban parks', 'per 100km2')
      COMMENT = '都市公園数（可住地面積100km2当たり）',

    pr."街区公園数（可住地面積100km2当たり）" AS "街区公園数（可住地面積100km2当たり）"
      WITH SYNONYMS ('街区公園', 'block parks', '近隣公園', 'per 100km2')
      COMMENT = '街区公園数（可住地面積100km2当たり）',

    pr."近隣公園数（可住地面積100km2当たり）" AS "近隣公園数（可住地面積100km2当たり）"
      WITH SYNONYMS ('近隣公園', 'district parks', 'per 100km2')
      COMMENT = '近隣公園数（可住地面積100km2当たり）',

    pr."運動公園数（可住地面積100km2当たり）" AS "運動公園数（可住地面積100km2当たり）"
      WITH SYNONYMS ('運動公園', 'sports parks', 'per 100km2')
      COMMENT = '運動公園数（可住地面積100km2当たり）'
  )

  DIMENSIONS (
    pr."調査年" AS "調査年"
      WITH SYNONYMS ('年', '年度', 'survey year', 'year', '時点')
      COMMENT = '調査年',

    pr."地域" AS "地域"
      WITH SYNONYMS ('都道府県', 'prefecture', 'region', 'area', '自治体')
      COMMENT = '地域（都道府県など）'

  );

-- ================================================================
-- Semantic View8: 建設企業 有価証券報告書 取り組み情報（定性）
-- 目的: 仮想建設企業の企業戦略書作成における参考資料
-- ================================================================
CREATE OR REPLACE SEMANTIC VIEW CONSTRUCTION_REFERENCE_INITIATIVES
  TABLES (
    ri AS FDUA_COMPETITION.PUBLIC.CONSTRUCTION_COMPANY_STRATEGY_REFERENCE
      WITH SYNONYMS (
        '参考企業取り組み', '建設企業の取り組み', '有価証券報告書',
        '開示情報', '定性情報', '戦略', 'strategy reference'
      )
      COMMENT = '実在する建設企業の有価証券報告書から切り出した取り組み情報（企業戦略書作成の参考用）'
  )
  FACTS (
    -- 取り組み内容（文章本体）
    ri."取り組み内容" AS ri."取り組み内容"
      WITH SYNONYMS (
        '取り組み内容', '本文', '記載内容', 'テキスト', 'description', 'details', 'narrative'
      )
      COMMENT = '有価証券報告書から切り出した取り組み内容（定性テキスト）'
  )
  DIMENSIONS (
    -- 参考企業名
    PUBLIC ri."企業" AS ri."企業"
      WITH SYNONYMS (
        '企業', '会社', '社名', 'company', 'company name'
      )
      COMMENT = '参考情報の対象となる実在企業（社名）',

    -- 有価証券報告書内の項目（章・セクション）
    PUBLIC ri."項目" AS ri."項目"
      WITH SYNONYMS (
        '項目', '章', 'セクション', '開示項目',
        'section', 'topic', 'category'
      )
      COMMENT = '有価証券報告書内の項目（例: 経営方針、サステナビリティ、事業等のリスク、MD&A、研究開発活動）'
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

