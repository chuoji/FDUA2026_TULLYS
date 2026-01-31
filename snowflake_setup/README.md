# Snowflake環境セットアップ

第4回金融データ活用チャレンジ向けのSnowflake環境を構築します。

## 構成

### Database
- **Database名**: `FDUA_COMPETITION`
- **Schema**: `PUBLIC`

### Tables（4テーブル）

| テーブル名 | 説明 | レコード数（想定） |
|-----------|------|------------------|
| **FINANCIAL_DATA** | 10社 x 3年分の財務データ（92列） | 30行 |
| **PROMPT_LOGS** | プロンプトログ（LLM入出力記録） | 実行ごと |
| **VERIFICATION_REPORTS** | 検証プロセスレポート | 実行ごと |
| **GENERATED_PROPOSALS** | 生成された提案書メタデータ | 実行ごと |

### Stages（5ステージ）

| Stage名 | 用途 |
|---------|------|
| **SECURITIES_REPORTS** | 有価証券報告書PDF（10社分） |
| **GENERATED_PROPOSALS** | 生成された提案書（.docx） |
| **PROMPT_LOGS_STAGE** | プロンプトログ（.docx） |
| **VERIFICATION_REPORTS_STAGE** | 検証プロセスレポート（.docx） |
| **TEMP_FILES** | 一時ファイル |

---

## セットアップ手順（最速）

### 前提条件
- Snowflakeアカウントへのアクセス権限
- Warehouse（XS以上推奨）
- ACCOUNTADMIN または同等のロール

---

### ⚡ クイックスタート（Snowsight UIで実行）

#### Step 0: クイックテスト（セットアップ完了後の確認用）
```sql
!source 00_quick_test.sql
```
※ セットアップ完了後に実行すると、全ての確認が一括で行えます

---

#### Step 1: Database, Tables, Stagesを一括作成

Snowflake Worksheet（Snowsight UI）で以下を順番に実行:

```sql
-- 1. Database & Schema
!source 01_database_setup.sql

-- 2. Tables作成（92列の財務データ + ログテーブル）
-- 注意: 日本語カラム名はダブルクォートで囲んであります
!source 02_create_tables.sql

-- 3. Stages作成（暗号化 + Directory有効）
!source 03_create_stages.sql
```

**または、各SQLファイルの内容をコピペして実行**

**重要**: 日本語カラム名を使用する場合、クエリでも必ずダブルクォートで囲んでください。
```sql
-- ✓ 正しい
SELECT "コード", "売上高" FROM FINANCIAL_DATA;

-- ✗ エラー
SELECT コード, 売上高 FROM FINANCIAL_DATA;
```

---

#### Step 2: データアップロード（2つの方法）

##### 方法A: Snowsight UI（推奨 - 簡単）

1. **CSVアップロード**:
   - Snowsight → Data → Databases → FDUA_COMPETITION → PUBLIC → Tables
   - FINANCIAL_DATA テーブルを選択 → 「Load Data」
   - `data/financial_data.csv` をドラッグ&ドロップ
   - File Format: CSV, Skip Header: 1, Encoding: UTF-8

2. **PDFアップロード**:
   - Snowsight → Data → Databases → FDUA_COMPETITION → PUBLIC → Stages
   - SECURITIES_REPORTS を選択 → 「+ Files」
   - `data/securities_report/` フォルダ内の10個のPDFを選択してアップロード

##### 方法B: SnowSQL CLI

```bash
# SnowSQLで接続
snowsql -a <account> -u <user>

# Database/Schemaを指定
USE DATABASE FDUA_COMPETITION;
USE SCHEMA PUBLIC;

# CSVアップロード
PUT file://data/financial_data.csv @~/staged AUTO_COMPRESS=FALSE;

# PDFアップロード（10社分）
PUT file://data/securities_report/*.pdf @SECURITIES_REPORTS;
```

---

#### Step 3: データロード確認

Worksheetで実行:

```sql
-- レコード数確認（30行: 10社 x 3年）
SELECT COUNT(*) FROM FINANCIAL_DATA;
-- 期待値: 30

-- 企業別確認
SELECT コード, 本社所在地, 業種分類, COUNT(*) AS YEARS
FROM FINANCIAL_DATA
GROUP BY コード, 本社所在地, 業種分類
ORDER BY コード;
-- 期待値: 10社、各3年分

-- PDFファイル確認
LIST @SECURITIES_REPORTS;
-- 期待値: 10ファイル
```

✅ 30行のデータと10個のPDFが確認できればセットアップ完了！

---

## データ確認

### 財務データ確認

```sql
-- 企業コード12044（茨城あずま建設）の3年分
SELECT コード, 本社所在地, 業種分類, YEAR, 売上高, 営業利益, 経常利益, 当期純利益
FROM FINANCIAL_DATA
WHERE コード = 12044
ORDER BY YEAR;
```

**期待される結果**:
| コード | 本社所在地 | 業種分類 | YEAR | 売上高 | 営業利益 | 経常利益 | 当期純利益 |
|-------|----------|---------|------|--------|---------|---------|-----------|
| 12044 | 茨城 | 総合建設・土木 | 2023 | 7,971,018,877 | 140,551,456 | 60,827,913 | -5,482,389 |
| 12044 | 茨城 | 総合建設・土木 | 2024 | 12,280,657,466 | 674,201,636 | 581,407,812 | 415,225,416 |
| 12044 | 茨城 | 総合建設・土木 | 2025 | 12,186,600,000 | 371,514,178 | 263,263,259 | 217,297,487 |

### PDFアップロード確認

```sql
LIST @SECURITIES_REPORTS;
```

**期待される結果**: 10ファイル
```
有価証券報告書（12044）.pdf
有価証券報告書（71768）.pdf
有価証券報告書（73617）.pdf
有価証券報告書（99702）.pdf
有価証券報告書（141634）.pdf
有価証券報告書（184226）.pdf
有価証券報告書（244359）.pdf
有価証券報告書（292640）.pdf
有価証券報告書（308582）.pdf
有価証券報告書（325042）.pdf
```

---

## トラブルシューティング

### エラー: "File format cannot be determined"
- CSVファイルがUTF-8エンコーディングか確認
- BOMなしUTF-8を推奨

### エラー: "Number of columns in file does not match"
- financial_data.csvのヘッダー列数（92列）とテーブル定義が一致しているか確認
- カラム名に特殊文字（丸括弧、全角記号）が含まれる場合はダブルクォートで囲む

### PDFアップロード失敗
- ファイルサイズ確認（1ファイル最大5GB）
- ファイル名に日本語が含まれる場合、UTF-8エンコーディングを確認

---

## 次のステップ

環境セットアップが完了したら:

1. **Streamlitアプリ初期化**:
   ```bash
   just new_streamlit fdua_baseline
   ```

2. **アプリ実装**: `streamlit/fdua_baseline/streamlit_app.py`を編集

3. **ローカル実行**:
   ```bash
   just run_streamlit fdua_baseline
   ```

4. **SiSデプロイ**:
   ```bash
   just deploy_streamlit fdua_baseline dev
   ```
