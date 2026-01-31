# FDUA Competition Template

第4回金融データ活用チャレンジ向けのベースラインソリューション

## コンペティション情報

### コンペのURL
- 公式サイト: [金融データ活用推進協会 (FDUA)](https://www.fdua.org/)
- コンペティションページ: [（金融庁共催）第4回金融データ活用チャレンジ](https://user.competition.signate.jp/ja/competition/detail/?competition=8fd1916845984ca1ae2d620731deae19)

### コンペの概要
第4回金融データ活用チャレンジは、企業の財務データと有価証券報告書を活用して成長戦略提案書を生成するコンペティションです。

本テンプレートは、以下の機能を提供するベースラインソリューションです。
- 財務データの分析と可視化
- 有価証券報告書（PDF）からの情報抽出
- Snowflake Cortex AIを活用した成長戦略提案書の自動生成
- 生成された提案書の検証機能

## インストールが必要なもの

### 必須ツール

1. **Python 3.13以上**
   ```bash
   python --version  # 3.13以上であることを確認
   ```

2. **uv (Pythonパッケージマネージャー)**
   ```bash
   # macOS / Linux
   curl -LsSf https://astral.sh/uv/install.sh | sh
   
   # または pip 経由
   pip install uv
   ```

3. **Snowflake CLI**
   ```bash
   # uv 経由でインストール（推奨）
   uv add snowflake-cli
   
   # または pip 経由
   pip install snowflake-cli
   ```

4. **Snowflakeアカウント**
   - Snowflakeアカウントへのアクセス権限
   - ACCOUNTADMIN または同等のロール
   - Warehouse（XS以上推奨）

### プロジェクトのセットアップ

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/TakumiMukaiyama/FDUA-competition-template
   cd FDUA-competition-template
   ```

2. **依存関係のインストール**
   ```bash
   uv sync
   ```

3. **Snowflake接続の設定**
   
   Snowflake CLIの接続設定を行います:
   ```bash
   snow connection add <connection-name>
   ```
   
   対話形式で以下を入力:
   - Account: Snowflakeアカウント識別子
   - User: ユーザー名
   - Password: パスワード（または認証方法）
   - Warehouse: 使用するWarehouse名
   - Database: `FDUA_COMPETITION`
   - Schema: `PUBLIC`
   - Role: `ACCOUNTADMIN` または適切なロール

4. **Snowflake環境のセットアップ**
   
   `snowflake_setup/` ディレクトリ内のSQLファイルを順番に実行して、データベース、テーブル、ステージを作成します。
   
   詳細は [snowflake_setup/README.md](./snowflake_setup/README.md) を参照してください。

## Streamlitアプリのデプロイ

### 前提条件

- Snowflake環境のセットアップが完了していること
- Snowflake CLIの接続設定が完了していること
- 環境変数 `SNOWFLAKE_WAREHOUSE` が設定されていること（または `snowflake.yml` で直接指定）

### デプロイ手順

1. **Streamlitアプリディレクトリに移動**
   ```bash
   cd streamlit/fdua-baseline
   ```

2. **環境変数の設定（必要に応じて）**
   ```bash
   export SNOWFLAKE_WAREHOUSE=<your-warehouse-name>
   ```

3. **Snowflake CLIを使用してデプロイ**
   ```bash
   # 開発環境へのデプロイ
   uv run snow streamlit deploy --replace --connection <connection-name>
   
   # または、接続名を省略してデフォルト接続を使用
   uv run snow streamlit deploy --replace
   ```

   **注意**: `--replace` オプションは既存のアプリを上書きします。

4. **デプロイの確認**
   
   デプロイが成功すると、Snowsight UIでStreamlitアプリにアクセスできるようになります。
   - Snowsight → Apps → Streamlit Apps → `fdua_baseline`

### ローカルでの実行

デプロイ前にローカルでテストする場合:

```bash
cd streamlit/fdua-baseline
uv run streamlit run streamlit_app.py
```

ブラウザで `http://localhost:8501` にアクセスしてアプリを確認できます。

### トラブルシューティング

- **接続エラー**: Snowflake CLIの接続設定を確認してください
- **Warehouseエラー**: 環境変数 `SNOWFLAKE_WAREHOUSE` が正しく設定されているか確認してください
- **権限エラー**: ACCOUNTADMINロールまたは適切な権限があることを確認してください

## プロジェクト構成

```
.
├── streamlit/
│   └── fdua-baseline/          # Streamlitアプリケーション
│       ├── streamlit_app.py    # メインアプリ
│       ├── common/             # 共通モジュール
│       ├── config/             # 設定ファイル
│       └── snowflake.yml       # Snowflake Native Apps設定
├── snowflake_setup/            # Snowflake環境セットアップSQL
│   ├── 01_database_setup.sql
│   ├── 02_create_tables.sql
│   └── ...
├── pyproject.toml              # Python依存関係
└── README.md                   # このファイル
```

## 参考
[Snowflake CLI インストールガイド](https://docs.snowflake.com/ja/developer-guide/snowflake-cli/installation/installation)