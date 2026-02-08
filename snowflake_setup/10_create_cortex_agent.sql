-- ================================================================
-- Cortex Agent作成
-- ================================================================
-- 4つのSemantic ViewをツールとしてCortex Agentを作成
-- 前提: 07_create_semantic_view.sql を実行済み
-- ================================================================

USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;
USE WAREHOUSE WH_XSMALL;

-- ================================================================
-- Step 1: Semantic Viewが作成されているか確認
-- ================================================================
SHOW SEMANTIC VIEWS LIKE '%SEMANTIC%';
SHOW SEMANTIC VIEWS LIKE 'FINANCIAL_DATA_%';

-- 期待される結果: 4つのSemantic View
-- - FINANCIAL_DATA_BASIC_AND_PL
-- - FINANCIAL_DATA_ASSETS
-- - FINANCIAL_DATA_LIABILITIES_AND_EQUITY
-- - SECURITIES_REPORTS_SEMANTIC

-- ================================================================
-- Step 2: Cortex Agent作成
-- ================================================================
-- 4つのSemantic ViewをCortex Analystツールとして紐付け

CREATE OR REPLACE AGENT FINANCIAL_DATA_AGENT
  COMMENT = '財務データ分析エージェント: 4つのSemantic Viewを使用して財務データと有価証券報告書を分析'
  PROFILE = '{
    "display_name": "財務データアナリスト",
    "avatar": "🏢",
    "color": "#1E3A8A"
  }'
  FROM SPECIFICATION
  $$
  # ================================================================
  # モデル設定
  # ================================================================
  models:
    orchestration: claude-4-sonnet

  # ================================================================
  # オーケストレーション設定
  # ================================================================
  orchestration:
    budget:
      tokens: 1000000

# ================================================================
# システムプロンプト（全フェーズ統合・完成版）
# ================================================================
instructions:
  system: |
    あなたは大手銀行の支店長として、建設業企業の経営者に向けて
    「実行可能で、資金調達・成長につながる成長戦略提案書」を作成する専門家です。

    本提案書の目的は以下の3点です。
    1. 経営者が意思決定できる
    2. 現場が動ける
    3. 銀行として支援判断ができる

    単なる分析レポートではなく、
    「結論 → 根拠 → 打ち手 → 数値効果 → 実行計画」
    の順で、必ず「次に何をすべきか」が分かる構成にしてください。

    断定的表現は避け、必ず根拠（財務データまたは有価証券報告書）を明示してください。

# ================================================================
# レポート設計思想（最重要・全フェーズ共通）
# ================================================================
  response: |
    ## レポート共通ルール（必須）

    ### 1. 冒頭に必ず入れるもの
    **エグゼクティブサマリー（1ページ相当）**
    - 現状評価の結論
    - 最重要KPI（現状 → 目標）
    - 最優先施策 TOP3
    - 必要投資額（概算レンジ）
    - 想定リスクと対応方針

    ### 2. 記述の基本順序
    数値 → 解釈 → 課題 → 戦略 → 施策 → 実行

    ### 3. 根拠表記ルール
    重要な主張には必ず以下を明示すること
    - 根拠（財務データ：○年度・○指標）
    - 根拠（有価証券報告書：○○セクション）

    ### 4. 施策フォーマット（必須）
    すべての施策は以下の形式で記載する

    - 目的
    - 現状課題（数値・定性根拠）
    - 具体的な打ち手
    - 必要投資額（レンジ可）
    - 期待効果（KPI・数値）
    - 実行期限（短期 / 中期 / 長期）
    - 主担当（経営 / 現場 / 外部）
    - 主なリスクと対策

    ### 5. 優先順位付けルール
    各施策を以下3軸で1〜5点評価し、合計点で順位付けする
    - Impact（効果の大きさ）
    - Feasibility（実行可能性）
    - Speed（効果発現の速さ）

# ================================================================
# フェーズ0：データ収集フェーズ（承認不要）
# ================================================================
orchestration: |
  ## フェーズ0：データ収集

  1. FinancialDataBasicAndPL
     - 基本情報
     - 損益計算書（3年分）

  2. FinancialDataAssets
     - 資産構成（3年分）

  3. FinancialDataLiabilitiesAndEquity
     - 負債・純資産
     - キャッシュフロー（3年分）

  4. SecuritiesReports
     - 有価証券報告書 full_text を取得
     - 以下観点で整理
       * 事業内容
       * 経営方針
       * 事業等のリスク
       * 設備投資
       * 人材・組織
       * 研究開発

# ================================================================
# フェーズ1：企業概要・現状分析
# ================================================================
  ## フェーズ1：企業概要・現状分析（約5,000字）

  ### 必須構成
  1. エグゼクティブサマリー
  2. 企業概要
     - 所在地・業種・従業員数・事業特性
  3. 外部環境分析
     - 地域特性
     - 建設業界動向
  4. 財務分析（3年分）
     - PL：売上・利益・利益率
     - BS：資産構成・自己資本比率
     - CF：営業CFの安定性
     - 運転資本：売掛金・未成工事・受入金
  5. 有価証券報告書分析
     - 競争優位性
     - 経営課題
     - 潜在リスク
  6. 課題整理
     - 構造的課題
     - 短期改善可能課題

  ### 出力
  - EXPORT_PROPOSAL_WORD（phase="phase1"）
  - ユーザー承認を必ず取得
  - 5,000文字以内

# ================================================================
# フェーズ2：成長戦略・施策提案
# ================================================================
  ## フェーズ2：成長戦略・施策提案（約7,000字）

  ### 戦略設計
  - 成長の軸を明確化
    （例：粗利率改善／単価向上／回転率改善）
  - 過去3年の分析と論理的に接続

  ### 施策カテゴリ（必須）
  1. 収益力強化（単価・粗利）
  2. 原価・生産性（DX・省力化）
  3. 人材（確保・定着・多能工化）
  4. 財務体質（運転資金・借入構造）
  5. 中長期成長（GX・新分野）

  ### 出力要件
  - 施策数：3〜5
  - 優先順位スコア付き
  - 財務・報告書根拠を必ず明示

  ### 出力
  - EXPORT_PROPOSAL_WORD（phase="phase2"）
  - ユーザー承認を必ず取得
  - 5,000文字以内

# ================================================================
# フェーズ3：効果試算・ロードマップ
# ================================================================
  ## フェーズ3：効果試算・ロードマップ（約3,000字）

  ### 必須構成
  1. 施策別 効果試算
     - 売上・利益・CFへの影響
     - 仮定条件を明示（レンジ可）
  2. 実行ロードマップ
     - 短期（〜1年）
     - 中期（1〜3年）
     - 長期（3年以上）
  3. 投資額と資金調達観点
     - 銀行支援余地（一般論）
  4. KPI設計・モニタリング方法

  ### 出力
  - EXPORT_PROPOSAL_WORD（phase="phase3"）
  - 最終確認を実施
  - 5,000文字以内

# ================================================================
# 完全版（全フェーズ統合）
# ================================================================
  ## 完全版生成（オプション）

  ユーザーから依頼があった場合：
  - フェーズ1〜3を統合
  - 重複表現を整理
  - 一貫したストーリーに再構成
  - EXPORT_PROPOSAL_WORD（phase="complete"）

# ================================================================
# 記述スタイル（全フェーズ共通）
# ================================================================
- 感覚的・抽象的表現は禁止
- 数値・根拠・次アクションで締める
- 専門用語は簡潔に補足
- 「だから何をすべきか」を必ず明示
- 箇条書きだけでなく、分かりやすく簡潔な文章で説明を入れる


    sample_questions:
      - question: "企業コード12044の成長戦略提案書を作成してください"
        answer: |
          以下のステップで提案書を段階的に作成します:

          【データ収集フェーズ】
          1. 財務データツール（FinancialDataBasicAndPL、FinancialDataAssets、FinancialDataLiabilitiesAndEquity）で2023-2025年の3年分のデータを取得
          2. SecuritiesReportsツールで有価証券報告書full_textを取得し、事業内容、リスク情報、経営方針を抽出

          【フェーズ1: 企業概要・分析】
          3. データ分析を基に、企業概要・分析（約5,000字）を作成
          4. ユーザーに提示し、承認を得る

          【フェーズ2: 成長戦略・提案】
          5. フェーズ1の承認後、地域特性、業界動向、GX/DX、人材確保の観点から成長戦略・提案（約7,000字）を作成
          6. ユーザーに提示し、承認を得る

          【フェーズ3: 効果試算・ロードマップ】
          7. フェーズ2の承認後、効果試算・ロードマップ（約3,000字）を作成
          8. 最終確認

      - question: "企業コード71768の財務状況を3年間で分析してください"
        answer: |
          FinancialDataBasicAndPL、FinancialDataAssets、FinancialDataLiabilitiesAndEquityの
          3つのツールを使用して、2023-2025年の財務データを取得し、売上高、営業利益率、
          自己資本比率、キャッシュフローの推移を分析します。

      - question: "企業コード73617の有価証券報告書から事業内容とリスクを抽出してください"
        answer: |
          SecuritiesReportsツールで企業コード73617の有価証券報告書full_textを取得し、
          「事業の内容」「事業等のリスク」セクションを抽出・要約します。

  # ================================================================
  # ツール定義
  # ================================================================
  tools:
    # ツール1: 基本情報 + 損益計算書（P/L）
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "FinancialDataBasicAndPL"
        description: |
          基本情報と損益計算書（P/L）を分析するツール。
          以下のデータを含みます:
          - 企業の基本情報（コード、所在地、業種、従業員数、資本金）
          - 売上高、営業利益、経常利益、当期純利益などの損益計算書データ
          - 売上原価、販管費の内訳
          - 売上高・売上原価・売上総利益の内訳（完成工事、不動産、商品）
          - 3年分のデータ（2023、2024、2025年）

    # ツール2: 貸借対照表（B/S）- 資産側
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "FinancialDataAssets"
        description: |
          貸借対照表の資産側（B/S Assets）を分析するツール。
          以下のデータを含みます:
          - 総資産、流動資産、固定資産
          - 有形固定資産、無形固定資産、投資その他の資産
          - 流動資産の詳細（現金、売掛金、完成工事未収入金、未成工事支出金、販売用不動産など）
          - 固定資産の詳細（建物、機械、土地、ソフトウェア、のれん、投資有価証券など）
          - 3年分のデータ（2023、2024、2025年）
        
    # ツール3: 貸借対照表（B/S）- 負債・純資産側 + キャッシュフロー
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "FinancialDataLiabilitiesAndEquity"
        description: |
          貸借対照表の負債・純資産側（B/S Liabilities & Equity）とキャッシュフロー計算書（C/F）を分析するツール。
          以下のデータを含みます:
          - 負債合計、流動負債、固定負債
          - 純資産と純資産の内訳（資本金、資本剰余金、利益剰余金、自己株式など）
          - 流動負債の詳細（買掛金、短期借入金、未成工事受入金、賞与引当金など）
          - 固定負債の詳細（長期借入金、社債、退職給付債務など）
          - キャッシュフロー（営業CF、投資CF、財務CF、現金及び現金同等物期末残高）
          - 3年分のデータ（2023、2024、2025年）

    # ツール4: 有価証券報告書（FULL_TEXT含む）
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "SecuritiesReports"
        description: |
          有価証券報告書のPDF全文とメタデータを分析するツール。
          以下のデータを含みます:
          - full_text: 有価証券報告書のPDF全文（重要: Cortex Analyst検索対象）
          - 文書タイトル、提出日、決算期、決算年度
          - ページ数、文字数、単語数
          - PDFファイル名、抽出日時

          このツールを使用して、企業の事業内容、リスク情報、経営方針、
          従業員の状況、研究開発活動など、有価証券報告書に記載された
          詳細な情報を取得できます。

    # ツール5: 有価証券報告書セマンティック検索（Cortex Search）
    - tool_spec:
        type: "cortex_search"
        name: "SecuritiesReportsSearch"
        description: |
          有価証券報告書をセマンティック検索するツール。
          自然言語クエリで有価証券報告書の中から関連する情報を高速に検索できます。

          主な用途:
          - 特定のキーワードやトピックに関連する記述を検索
          - 「DXへの取り組み」「環境対策」「人材確保の課題」などのテーマで検索
          - 複数企業の報告書から横断的に情報を収集

          検索可能な属性:
          - company_code: 企業コードでフィルタ
          - fiscal_year: 決算年度でフィルタ
          - fiscal_period: 決算期でフィルタ

          使用例:
          - query="DXやデジタル化への取り組み", filter={"@eq": {"company_code": 12044}}
          - query="環境技術や省エネルギー対策", filter={"@eq": {"fiscal_year": 2025}}
          - query="人材確保や働き方改革"

          注意: このツールはセマンティック検索（意味的類似度）なので、
          キーワード完全一致ではなく、意味的に関連する情報を取得します。

    # ツール6: Word出力関数（カスタムツール）
    - tool_spec:
        type: "generic"
        name: "EXPORT_PROPOSAL_WORD"
        description: |
          提案書をWord（.docx）形式でエクスポートするツール。
          各フェーズ完成時または最終完成時に使用します。

          使用タイミング:
          - フェーズ1完成後: phase="phase1"でエクスポート
          - フェーズ2完成後: phase="phase2"でエクスポート
          - フェーズ3完成後: phase="phase3"でエクスポート
          - 完全版生成時: phase="complete"でエクスポート

          出力結果（JSON文字列）:
          - file_path: Stage上のファイルパス
          - presigned_url: ダウンロード可能なURL（7日間有効）
          - file_size_kb: ファイルサイズ（KB）
          - filename: ファイル名

          重要: ダウンロードリンク（presigned_url）を必ずユーザーに提示してください。
        input_schema:
          type: object
          properties:
            company_code:
              type: number
              description: "企業コード"
            proposal_text:
              type: string
              description: "Markdown形式の提案書本文"
            phase:
              type: string
              description: "フェーズ名（phase1/phase2/phase3/complete）"
          required:
            - company_code
            - proposal_text
            - phase

  # ================================================================
  # ツールリソース設定
  # ================================================================
  tool_resources:
    # ツール1のSemantic View指定
    FinancialDataBasicAndPL:
      semantic_view: "FDUA_COMPETITION.PUBLIC.FINANCIAL_DATA_BASIC_AND_PL"
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH

    # ツール2のSemantic View指定
    FinancialDataAssets:
      semantic_view: "FDUA_COMPETITION.PUBLIC.FINANCIAL_DATA_ASSETS"
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH

    # ツール3のSemantic View指定
    FinancialDataLiabilitiesAndEquity:
      semantic_view: "FDUA_COMPETITION.PUBLIC.FINANCIAL_DATA_LIABILITIES_AND_EQUITY"
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH

    # ツール4のSemantic View指定
    SecuritiesReports:
      semantic_view: "FDUA_COMPETITION.PUBLIC.SECURITIES_REPORTS_SEMANTIC"
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH

    # ツール5のCortex Search Service指定
    SecuritiesReportsSearch:
      search_service: "FDUA_COMPETITION.PUBLIC.SECURITIES_REPORTS_SEARCH"
      max_results: 10
      id_column: "COMPANY_CODE"
      title_column: "DOCUMENT_TITLE"

    # ツール6のカスタム関数指定（Word出力）
    EXPORT_PROPOSAL_WORD:
      type: procedure
      identifier: "FDUA_COMPETITION.PUBLIC.EXPORT_PROPOSAL_TO_WORD"
      name: "EXPORT_PROPOSAL_TO_WORD(NUMBER, VARCHAR, VARCHAR)"
      execution_environment:
        type: warehouse
        warehouse: WH_XSMALL

  $$;

-- ================================================================
-- Step 3: Cortex Agentの確認
-- ================================================================
SHOW AGENTS;

-- Agent詳細を確認
DESC AGENT FINANCIAL_DATA_AGENT;

-- ================================================================
-- Step 4: テストクエリ
-- ================================================================
-- Cortex AgentをSnowsight UIまたはREST APIでテスト

-- ■ 提案書生成のテストクエリ（メインタスク - 段階的承認プロセス）:
-- 注意: 以下のクエリでは、Agentが3つのフェーズに分けて提案書を作成します。
--       各フェーズで承認確認メッセージが表示されるので、「OK」や「進めてください」と返答してください。
--
-- 1. "企業コード12044の成長戦略提案書を作成してください"
--    → フェーズ1（企業概要・分析）が表示される → 承認 → フェーズ2（成長戦略・提案）が表示される → 承認 → フェーズ3（効果試算・ロードマップ）が表示される
--
-- 2. "企業コード71768について、15,000字以内で成長戦略提案書を作成してください"
--    → 同様に3つのフェーズで段階的に作成
--
-- 3. "企業コード73617の提案書を作成してください。地域性とGX/DXの観点を重視してください"
--    → 同様に3つのフェーズで段階的に作成

-- ■ 財務分析のテストクエリ:
-- 4. "企業コード12044の財務状況を3年間（2023-2025年）で詳しく分析してください"
-- 5. "2025年度の営業利益率が最も高い企業を教えてください"
-- 6. "自己資本比率が最も高い企業トップ3を教えてください"

-- ■ 有価証券報告書分析のテストクエリ:
-- 7. "企業コード12044の有価証券報告書から、事業内容とリスク情報を抽出してください"
-- 8. "企業コード71768の有価証券報告書から、GX/DXへの取り組みを探してください"
-- 9. "企業コード73617の有価証券報告書から、人材確保の課題を抽出してください"

-- ■ セマンティック検索のテストクエリ（Cortex Search）:
-- 10. "SecuritiesReportsSearchツールを使って、DXやデジタル化への取り組みに関する情報を企業コード12044から検索してください"
-- 11. "全企業の有価証券報告書から、環境技術や省エネルギー対策に関する記述を検索してください"
-- 12. "人材確保や働き方改革について言及している企業を検索してください"

-- ================================================================
-- トラブルシューティング
-- ================================================================

-- エラーが発生した場合:

-- 1. Semantic Viewが存在するか確認
-- SHOW VIEWS LIKE '%SEMANTIC%';

-- 2. Semantic Viewのデータを確認
-- SELECT * FROM FINANCIAL_DATA_BASIC_AND_PL LIMIT 5;

-- 3. Cortex Agentを再作成
-- DROP AGENT IF EXISTS FINANCIAL_DATA_AGENT;
-- -- 上記のCREATE文を再実行

-- 4. 権限を確認
-- SHOW GRANTS ON SCHEMA PUBLIC;
-- SHOW GRANTS ON VIEW FINANCIAL_DATA_BASIC_AND_PL;

-- ================================================================
-- 注意事項
-- ================================================================
-- 1. Cortex Agentの作成には、アカウントでCortex機能が有効になっている必要があります
--
-- 2. 5つのツールは、Cortex Agentが自動的に使い分けます:
--    - 4つのSemantic View（Text-to-SQL）
--    - 1つのCortex Search Service（セマンティック検索）
--
-- 3. company_code を使用して、複数のビューからデータを統合できます
--
-- 4. 有価証券報告書の分析:
--    - SecuritiesReportsツール: 企業全体のfull_textを取得
--    - SecuritiesReportsSearchツール: 特定トピックをセマンティック検索（不足情報の補強用）
--
-- 5. 段階的承認プロセス（重要）:
--    提案書作成は3つのフェーズに分かれます:
--    - フェーズ1: 企業概要・分析 → ユーザー承認 → 次へ
--    - フェーズ2: 成長戦略・提案 → ユーザー承認 → 次へ
--    - フェーズ3: 効果試算・ロードマップ → 完成
--    各フェーズで「OK」「進めてください」などと返答して次に進んでください
--
-- 6. Cortex Searchの使用ルール:
--    - 不足情報の補強目的のみで使用
--    - ユーザーから修正要求があった場合に使用
--    - 最初のデータ収集時には無闇に使用しない
--
-- 7. Cortex Searchの利用には、SECURITIES_REPORTS_SEARCHサービスが必要です
--    作成: 08_create_cortex_search.sql を実行
--
-- 8. Cortex Agentは、REST API経由で呼び出すことができます
--    エンドポイント: /api/v2/databases/{database}/schemas/{schema}/agents/{agent_name}:run
--
-- 9. Streamlitアプリから呼び出す場合は、common/llm_generator.py の
--    CortexAgentClient を使用してください

-- ================================================================
-- 次のステップ
-- ================================================================
-- 1. Cortex Searchサービスを作成（08_create_cortex_search.sql）
-- 2. このファイル全体を実行してCortex Agentを再作成
-- 3. Snowsight UIでCortex Agentをテスト（特にSecuritiesReportsSearchツールを試す）
-- 4. common/llm_generator.py でエージェント名を "FINANCIAL_DATA_AGENT" に更新
-- 5. Streamlitアプリからテスト
