"""
FDUA Competition Baseline - メインアプリ
成長戦略提案書生成システム
"""

import streamlit as st
import json
import datetime
from common.snowflake_util import SnowflakeConnection
from common.data_loader import get_companies, load_financial_data, load_pdf_data
from common.llm_generator import CortexAgentClient
from common.docx_writer import create_proposal_docx, create_verification_report_txt
from common.validator import validate_proposal

# ページ設定
st.set_page_config(
    page_title="FDUA Baseline - 提案書生成",
    page_icon="🏢",
    layout="wide"
)

# セッション状態の初期化
if 'generation_logs' not in st.session_state:
    st.session_state.generation_logs = []
if 'generated_proposals' not in st.session_state:
    st.session_state.generated_proposals = {}
if 'verification_reports' not in st.session_state:
    st.session_state.verification_reports = {}
if 'threads' not in st.session_state:
    st.session_state.threads = {}  # {thread_id: {metadata}}
if 'current_thread_id' not in st.session_state:
    st.session_state.current_thread_id = None

# タイトル
st.title("🏢 FDUA Competition Baseline")
st.markdown("### 第4回金融データ活用チャレンジ - 成長戦略提案書生成")
st.markdown("---")

# Snowflake接続
@st.cache_resource
def get_snowflake_connection():
    """Snowflake接続を取得"""
    return SnowflakeConnection()

try:
    sf_conn = get_snowflake_connection()
    session = sf_conn.get_client()
    st.sidebar.success("✓ Snowflake接続完了")

except Exception as e:
    st.error(f"Snowflake接続エラー: {e}")
    st.stop()

# 企業一覧を取得
@st.cache_data
def load_companies():
    """企業一覧をキャッシュ"""
    return get_companies(session)

try:
    companies = load_companies()
    distinct_companies = list(set(c['company_code'] for c in companies))
    st.sidebar.success(f"✓ {len(distinct_companies)}社のデータを読み込み")
except Exception as e:
    st.error(f"企業データ読み込みエラー: {e}")
    st.stop()

# サイドバー: 企業選択
st.sidebar.markdown("## 企業選択")
company_options = {
    f"{c['company_code']} - {c['location']} ({c['industry']})": c['company_code']
    for c in companies
}
selected_company_label = st.sidebar.selectbox(
    "企業を選択してください",
    options=list(company_options.keys())
)
selected_company_code = company_options[selected_company_label]

# 選択された企業の情報を表示
selected_company = next(c for c in companies if c['company_code'] == selected_company_code)
st.sidebar.markdown(f"""
**企業情報**
- コード: {selected_company['company_code']}
- 所在地: {selected_company['location']}
- 業種: {selected_company['industry']}
- 従業員数: {selected_company.get('employees', 'N/A')}人
- 資本金: {selected_company.get('capital', 'N/A')}億円
""")

# 会話管理
st.sidebar.markdown("---")
st.sidebar.markdown("## 会話履歴")

# 新しい会話を開始ボタン
if st.sidebar.button("➕ 新しい会話を開始", use_container_width=True):
    st.session_state.current_thread_id = None
    st.rerun()

# 現在の会話
if st.session_state.current_thread_id and st.session_state.current_thread_id in st.session_state.threads:
    current_thread = st.session_state.threads[st.session_state.current_thread_id]
    st.sidebar.success(f"**現在の会話**\n{current_thread['title']}")
else:
    st.sidebar.info("新しい会話")

# 過去の会話履歴
if st.session_state.threads:
    st.sidebar.markdown("### 過去の会話")

    # 更新日時でソート（新しい順）
    sorted_threads = sorted(
        st.session_state.threads.items(),
        key=lambda x: x[1]['updated_at'],
        reverse=True
    )

    for thread_id, thread_info in sorted_threads:
        is_current = thread_id == st.session_state.current_thread_id

        with st.sidebar.container():
            col1, col2 = st.columns([4, 1])

            with col1:
                # スレッド選択ボタン
                button_type = "primary" if is_current else "secondary"
                if st.button(
                    thread_info['title'],
                    key=f"thread_{thread_id}",
                    use_container_width=True,
                    type=button_type
                ):
                    st.session_state.current_thread_id = thread_id
                    st.rerun()

            with col2:
                # 削除ボタン
                if st.button("🗑️", key=f"delete_{thread_id}"):
                    del st.session_state.threads[thread_id]
                    if st.session_state.current_thread_id == thread_id:
                        st.session_state.current_thread_id = None
                    st.rerun()

            # メタデータ表示
            st.sidebar.caption(f"企業: {thread_info['company_code']} | {thread_info['updated_at']}")
else:
    st.sidebar.info("会話履歴がありません")

# メインエリア
col1, col2 = st.columns([2, 1])

with col1:
    st.markdown("### 提案書生成")

    # Cortex Agent設定
    agent_name = "FINANCIAL_DATA_AGENT"
    st.info(f"使用するCortex Agent: **{agent_name}**")

    # 選択されたスレッドの提案書を表示
    if st.session_state.current_thread_id and st.session_state.current_thread_id in st.session_state.threads:
        thread = st.session_state.threads[st.session_state.current_thread_id]
        if 'proposal' in thread:
            st.markdown("---")
            st.markdown("### 📄 生成済み提案書")
            with st.expander("提案書を表示", expanded=True):
                st.markdown(thread['proposal']['text'])
                st.download_button(
                    label="📥 提案書.docxをダウンロード",
                    data=thread['proposal']['docx'],
                    file_name=f"{thread['company_code']}.docx",
                    mime="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    key=f"dl_proposal_{thread['thread_id']}"
                )
                st.download_button(
                    label="📋 検証レポート.txtをダウンロード",
                    data=thread['proposal']['verification'],
                    file_name=f"verification_{thread['company_code']}.txt",
                    mime="text/plain",
                    key=f"dl_verification_{thread['thread_id']}"
                )
            st.markdown("---")

    # 生成ボタン
    if st.button("🚀 提案書を生成する", type="primary", use_container_width=True):
        with st.spinner(f"企業コード {selected_company_code} の提案書を生成中..."):
            try:
                # タイムスタンプ
                start_time = datetime.datetime.now()

                # 1. 財務データ読み込み（プロンプトに含める）
                financial_status = st.status("📊 財務データを読み込み中...", expanded=False)
                try:
                    with financial_status:
                        financial_data = load_financial_data(session, selected_company_code)
                        # DataFrameをテキスト形式に変換
                        financial_summary = f"""
                                            ## 財務データ（{selected_company_code}）

                                            ### 2023-2025年の財務推移
                                            {financial_data.to_string()}
                                            """
                    financial_status.update(label="✅ 財務データ読み込み完了", state="complete")
                except Exception as e:
                    financial_status.update(label="❌ 財務データ読み込み失敗", state="error")
                    st.error(f"❌ 財務データの読み込みに失敗しました: {e}")
                    import traceback
                    st.code(traceback.format_exc())
                    st.stop()

                # 2. PDFデータ読み込み（検証用）
                pdf_status = st.status("📄 PDFデータを読み込み中...", expanded=False)
                try:
                    with pdf_status:
                        pdf_data = load_pdf_data(session, selected_company_code, use_table=True)
                    pdf_status.update(label="✅ PDFデータ読み込み完了", state="complete")
                except Exception as e:
                    pdf_status.update(label="❌ PDFデータ読み込み失敗", state="error")
                    st.error(f"❌ PDFデータの読み込みに失敗しました: {e}")
                    import traceback
                    st.code(traceback.format_exc())
                    st.stop()

                # 3. Cortex Agentで提案書生成
                status_container = st.status("🤖 Cortex Agentで提案書を生成中...", expanded=True)

                try:
                    with status_container:
                        # イベントハンドラー
                        progress_text = st.empty()

                        def on_event(event_type, data):
                            if event_type == "request_start":
                                progress_text.write(f"📤 リクエスト送信中 (クエリ長: {data['query_length']:,}文字)")
                            elif event_type == "response_received":
                                progress_text.write(f"📥 レスポンス受信 (タイプ: {data['response_type']})")
                            elif event_type == "response_parsed":
                                progress_text.write(f"✅ レスポンス解析完了 (キー: {', '.join(data['keys'])})")
                            elif event_type == "error":
                                progress_text.write(f"❌ エラー: {data['error']}")

                        client = CortexAgentClient(
                            sf_conn,
                            "FDUA_COMPETITION",
                            "PUBLIC",
                            agent_name
                        )

                        # スレッドID管理（永続化）
                        if st.session_state.current_thread_id and st.session_state.current_thread_id in st.session_state.threads:
                            # 既存のスレッドを再利用
                            thread_id = st.session_state.current_thread_id
                            client.thread_id = thread_id
                            progress_text.write(f"🧵 既存のスレッドを使用: {thread_id[:16]}...")

                            # 更新日時を更新
                            st.session_state.threads[thread_id]['updated_at'] = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                        else:
                            # 新しいスレッドを作成
                            progress_text.write("🧵 新しいスレッドを作成中...")
                            thread_id = client.create_thread("fdua-baseline", on_event=on_event)
                            st.session_state.current_thread_id = thread_id

                            # スレッドメタデータを保存
                            now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                            st.session_state.threads[thread_id] = {
                                'thread_id': thread_id,
                                'title': f"企業{selected_company_code}の提案書",
                                'company_code': selected_company_code,
                                'company_name': selected_company['location'],
                                'created_at': now,
                                'updated_at': now
                            }
                            progress_text.write(f"✓ スレッドを作成しました: {thread_id[:16]}...")

                        # プロンプト構築（PDF全文はツールから取得させる）
                        query = f"""企業コード{selected_company_code}の成長戦略提案書を作成してください。

【必須要件】
- 最大15,000字以内
- 以下の3部構成:
  1. 企業概要・分析 (約5,000字)
  2. 成長戦略・提案 (約7,000字)
  3. 効果試算・ロードマップ (約3,000字)

【評価基準（5つの視点）】
1. 全体構成: 過去3年の分析と未来の戦略が論理的に接続されているか
2. 地域性: 所在地の特性（{selected_company['location']}）を踏まえた提案か
3. 業界特性: {selected_company['industry']}の販路・商流を理解した提案か
4. GX/DX: 環境技術・省力化技術への対応策を提案できているか
5. 人材/需要: 需要減退・人材不足への実効性ある解決策を示せているか

【データ取得方法】
1. **財務データ**: FinancialDataBasicAndPL、FinancialDataAssets、FinancialDataLiabilitiesAndEquityの各ツールで企業コード{selected_company_code}の2023-2025年の3年分のデータを取得してください
2. **有価証券報告書**: SecuritiesReportsツールで企業コード{selected_company_code}の有価証券報告書full_textを取得し、事業内容、リスク情報、経営方針、従業員の状況、研究開発活動などの情報を抽出してください

上記のツールを使用してデータを取得・分析し、具体的な数値と根拠を明記した成長戦略提案書を作成してください。
"""

                        # Agent呼び出し（ストリーミング処理付き）
                        progress_text.write("🤖 Cortex Agentを呼び出し中...")

                        # API呼び出し開始時刻
                        api_start = datetime.datetime.now()
                        response = client.call_agent(query, on_event=on_event)
                        api_end = datetime.datetime.now()
                        api_duration = (api_end - api_start).total_seconds()

                        progress_text.write(f"⏱️ API呼び出し時間: {api_duration:.2f}秒")

                        # SSEイベント配列をパース
                        content = response.get('content', [])

                        # contentの型を確認してパース
                        if isinstance(content, str):
                            try:
                                events = json.loads(content)
                            except json.JSONDecodeError:
                                st.error(f"レスポンスのパースに失敗しました: {content[:200]}")
                                events = []
                        elif isinstance(content, list):
                            events = content
                        else:
                            st.error(f"予期しないレスポンス型: {type(content)}")
                            events = []

                        # 表示用のプレースホルダー
                        status_placeholder = st.empty()
                        thinking_placeholder = st.empty()
                        tool_placeholder = st.empty()
                        streaming_placeholder = st.empty()

                        # 状態管理
                        accumulated_text = ""
                        accumulated_thinking = ""
                        proposal_text = ""
                        tool_history = []
                        current_tool = None

                        # イベントを順次処理
                        for event in events:
                            # イベントが文字列の場合はパース
                            if isinstance(event, str):
                                try:
                                    event = json.loads(event)
                                except json.JSONDecodeError:
                                    progress_text.write(f"⚠️ イベントのパースに失敗: {event[:100]}")
                                    continue

                            # イベントが辞書でない場合はスキップ
                            if not isinstance(event, dict):
                                progress_text.write(f"⚠️ 予期しないイベント型: {type(event)}")
                                continue

                            event_type = event.get('event', '')
                            data = event.get('data', {})

                            # ステータス更新
                            if event_type == 'response.status':
                                status_msg = data.get('message', '')
                                status_placeholder.info(f"🤖 ステータス: {status_msg}")

                            # 思考プロセス（デルタ）
                            elif event_type == 'response.thinking.delta':
                                thinking_text = data.get('text', '')
                                accumulated_thinking += thinking_text
                                # 思考プロセスを表示（先頭300文字）
                                preview = accumulated_thinking[:300]
                                if len(accumulated_thinking) > 300:
                                    preview += "..."
                                thinking_placeholder.markdown(f"💭 **思考中**: {preview}")

                            # 思考プロセス完了
                            elif event_type == 'response.thinking':
                                thinking_placeholder.empty()
                                accumulated_thinking = ""

                            # ツール使用開始
                            elif event_type == 'response.tool_use':
                                tool_name = data.get('name', '')
                                tool_use_id = data.get('tool_use_id', '')
                                current_tool = {'name': tool_name, 'id': tool_use_id, 'status': '実行中'}
                                tool_history.append(current_tool)
                                progress_text.write(f"🔧 ツール実行中: {tool_name}")

                            # ツール結果ステータス
                            elif event_type == 'response.tool_result.status':
                                if current_tool:
                                    result_status = data.get('status', '')
                                    current_tool['status'] = result_status

                            # ツール結果
                            elif event_type == 'response.tool_result':
                                tool_name = data.get('name', '')
                                tool_status = data.get('status', '')
                                progress_text.write(f"✅ ツール完了: {tool_name} ({tool_status})")

                                # ツール履歴を表示
                                tool_summary = "\n".join([
                                    f"- {t['name']}: {t['status']}" for t in tool_history
                                ])
                                tool_placeholder.markdown(f"**ツール利用履歴**\n{tool_summary}")

                            # テキスト生成（デルタ）- ストリーミング表示
                            elif event_type == 'response.text.delta':
                                delta_text = data.get('text', '')
                                accumulated_text += delta_text
                                # リアルタイムで表示を更新
                                streaming_placeholder.markdown(f"### 📝 生成中...\n\n{accumulated_text}")

                            # 完成したテキストブロック
                            elif event_type == 'response.text':
                                # deltaで既に蓄積済み
                                pass

                            # 最終レスポンス
                            elif event_type == 'response':
                                # 最終的な完全なテキストを取得
                                if 'content' in data:
                                    for item in data['content']:
                                        if isinstance(item, dict) and item.get('type') == 'text':
                                            proposal_text = item.get('text', '')
                                            break

                            # doneイベント
                            elif event_type == 'done':
                                pass

                        # ストリーミング表示をクリア
                        status_placeholder.empty()
                        thinking_placeholder.empty()
                        streaming_placeholder.empty()

                        # デバッグ: レスポンス構造を表示
                        with st.expander("🔍 Debug: イベント情報", expanded=False):
                            st.write(f"スレッドID: {thread_id}")
                            st.write(f"総イベント数: {len(events)}")

                            # イベントタイプを安全に抽出
                            event_types = []
                            for e in events:
                                if isinstance(e, dict):
                                    event_types.append(e.get('event', 'unknown'))
                                elif isinstance(e, str):
                                    try:
                                        parsed_e = json.loads(e)
                                        event_types.append(parsed_e.get('event', 'unknown'))
                                    except:
                                        event_types.append('parse_error')
                                else:
                                    event_types.append(f'type:{type(e).__name__}')

                            st.write("イベントタイプ別カウント:")
                            from collections import Counter
                            st.json(dict(Counter(event_types)))
                            st.write(f"最終テキスト長: {len(proposal_text)}")
                            st.write(f"ツール利用回数: {len(tool_history)}")

                            # ツール詳細情報
                            st.markdown("### ツール実行詳細")
                            for i, tool in enumerate(tool_history):
                                st.markdown(f"**ツール {i+1}: {tool['name']}**")
                                st.write(f"- ステータス: {tool['status']}")
                                st.write(f"- ID: {tool['id']}")

                            # ツール結果を詳細確認
                            st.markdown("### ツール実行結果の詳細")
                            tool_results = []
                            for event in events:
                                # イベントを辞書に変換
                                event_dict = None
                                if isinstance(event, dict):
                                    event_dict = event
                                elif isinstance(event, str):
                                    try:
                                        event_dict = json.loads(event)
                                    except:
                                        continue

                                # ツール結果を抽出
                                if event_dict and event_dict.get('event') == 'response.tool_result':
                                    data = event_dict.get('data', {})
                                    tool_results.append({
                                        'name': data.get('name'),
                                        'status': data.get('status'),
                                        'type': data.get('type'),
                                        'content': data.get('content', []),
                                        'tool_use_id': data.get('tool_use_id')
                                    })

                            if tool_results:
                                st.write(f"ツール結果数: {len(tool_results)}")
                                for i, result in enumerate(tool_results):
                                    status_color = "🟢" if result['status'] == 'success' else "🔴"
                                    st.markdown(f"{status_color} **ツール結果 {i+1}: {result['name']}**")
                                    st.write(f"- ステータス: {result['status']}")
                                    st.write(f"- タイプ: {result['type']}")
                                    st.write(f"- コンテンツ項目数: {len(result['content'])}")

                                    # コンテンツの詳細表示
                                    for j, content_item in enumerate(result['content']):
                                        with st.expander(f"コンテンツ項目 {j+1}", expanded=False):
                                            if isinstance(content_item, dict):
                                                # SQLクエリの抽出
                                                if 'sql_query' in content_item:
                                                    st.markdown("**実行されたSQLクエリ:**")
                                                    st.code(content_item['sql_query'], language='sql')

                                                # result_setの詳細表示
                                                if 'result_set' in content_item:
                                                    result_set = content_item['result_set']
                                                    st.markdown("**Result Set:**")
                                                    if isinstance(result_set, dict):
                                                        metadata = result_set.get('resultSetMetaData', {})
                                                        num_rows = metadata.get('numRows', 'N/A')
                                                        st.markdown(f"- numRows: `{num_rows}`")
                                                        st.markdown(f"- statementHandle: `{result_set.get('statementHandle', 'N/A')}`")

                                                        # numRowsが0の場合は警告
                                                        if num_rows == 0:
                                                            st.warning("⚠️ データが取得できていません (numRows = 0)")

                                                    st.json(result_set)

                                                # 全体のJSON表示
                                                st.markdown("**全データ:**")
                                                st.json(content_item)
                                            else:
                                                st.text(str(content_item))

                                    # エラーの場合は詳細表示
                                    if result['status'] != 'success':
                                        st.error("エラー詳細:")
                                        st.json(result)
                            else:
                                st.warning("ツール結果が見つかりません")

                            # 環境情報
                            st.markdown("### 環境情報")
                            st.write("- Database: FDUA_COMPETITION")
                            st.write("- Schema: PUBLIC")
                            st.write(f"- Agent: {agent_name}")
                            st.write(f"- Warehouse: {session.get_current_warehouse()}")
                            st.write(f"- Role: {session.get_current_role()}")

                        progress_text.write(f"✨ 生成完了 (文字数: {len(proposal_text):,}字)")

                    status_container.update(label="✅ 提案書生成完了", state="complete")
                except Exception as e:
                    status_container.update(label="❌ Cortex Agent呼び出しに失敗", state="error")
                    st.error(f"❌ Cortex Agentでの提案書生成に失敗しました: {e}")
                    import traceback
                    st.code(traceback.format_exc())
                    st.stop()

                end_time = datetime.datetime.now()
                duration = (end_time - start_time).total_seconds()

                # 4. .docx生成
                st.write("📝 .docxファイルを生成中...")
                try:
                    proposal_docx = create_proposal_docx(selected_company_code, proposal_text)
                except Exception as e:
                    st.error(f"❌ .docxファイルの生成に失敗しました: {e}")
                    import traceback
                    st.code(traceback.format_exc())
                    st.stop()

                # 5. 検証
                st.write("✅ 検証中...")
                try:
                    validation_result = validate_proposal(
                        proposal_text,
                        financial_data,
                        pdf_data
                    )
                except Exception as e:
                    st.error(f"❌ 提案書の検証に失敗しました: {e}")
                    import traceback
                    st.code(traceback.format_exc())
                    st.stop()

                # 6. 検証レポート生成
                st.write("📋 検証レポートを生成中...")
                try:
                    verification_txt = create_verification_report_txt(
                        selected_company_code,
                        validation_result
                    )
                except Exception as e:
                    st.error(f"❌ 検証レポートの生成に失敗しました: {e}")
                    import traceback
                    st.code(traceback.format_exc())
                    st.stop()

                # 7. セッションに保存
                st.session_state.generated_proposals[selected_company_code] = {
                    'docx': proposal_docx,
                    'text': proposal_text,
                    'timestamp': start_time,
                    'duration': duration
                }
                st.session_state.verification_reports[selected_company_code] = verification_txt

                # スレッドにも提案書を保存
                if thread_id in st.session_state.threads:
                    st.session_state.threads[thread_id]['proposal'] = {
                        'text': proposal_text,
                        'docx': proposal_docx,
                        'verification': verification_txt,
                        'duration': duration,
                        'tool_history': tool_history
                    }

                # 8. 生成ログに追加
                st.session_state.generation_logs.append({
                    'timestamp': start_time.isoformat(),
                    'company_code': selected_company_code,
                    'company_info': selected_company,
                    'prompt': query,
                    'response': proposal_text,
                    'validation': validation_result,
                    'duration_seconds': duration
                })

                st.success(f"✅ 提案書の生成が完了しました！（所要時間: {duration:.1f}秒）")

            except Exception as e:
                st.error(f"❌ 予期しないエラーが発生しました: {e}")
                import traceback
                with st.expander("🔍 Traceback詳細", expanded=True):
                    st.code(traceback.format_exc())

with col2:
    st.markdown("### 生成済み提案書")

    if st.session_state.generated_proposals:
        for code in sorted(st.session_state.generated_proposals.keys()):
            data = st.session_state.generated_proposals[code]

            with st.expander(f"📄 企業コード {code}"):
                st.write(f"生成時刻: {data['timestamp'].strftime('%Y-%m-%d %H:%M:%S')}")
                st.write(f"所要時間: {data['duration']:.1f}秒")
                st.write(f"文字数: {len(data['text']):,}字")

                # ダウンロードボタン
                st.download_button(
                    label="📥 提案書.docxをダウンロード",
                    data=data['docx'],
                    file_name=f"{code}.docx",
                    mime="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    key=f"download_proposal_{code}"
                )

                # 検証レポート
                if code in st.session_state.verification_reports:
                    st.download_button(
                        label="📋 検証レポート.txtをダウンロード",
                        data=st.session_state.verification_reports[code],
                        file_name=f"verification_{code}.txt",
                        mime="text/plain",
                        key=f"download_verification_{code}"
                    )
    else:
        st.info("まだ提案書が生成されていません")

# 下部: 生成ログ出力
st.markdown("---")
st.markdown("### 📊 生成ログ")

col_log1, col_log2 = st.columns([3, 1])

with col_log1:
    st.write(f"累計生成数: **{len(st.session_state.generation_logs)}件**")

with col_log2:
    if st.button("📥 生成ログを出力 (.txt)", type="secondary", use_container_width=True):
        if not st.session_state.generation_logs:
            st.warning("生成ログがありません")
        else:
            # 生成ログをテキスト形式で作成
            log_lines = []
            log_lines.append("=" * 80)
            log_lines.append("FDUA Competition - 提案書生成ログ")
            log_lines.append(f"出力日時: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            log_lines.append(f"総生成数: {len(st.session_state.generation_logs)}件")
            log_lines.append("=" * 80)
            log_lines.append("")

            for i, log in enumerate(st.session_state.generation_logs, 1):
                log_lines.append(f"{'=' * 80}")
                log_lines.append(f"生成 #{i}")
                log_lines.append(f"{'=' * 80}")
                log_lines.append(f"タイムスタンプ: {log['timestamp']}")
                log_lines.append(f"企業コード: {log['company_code']}")
                log_lines.append(f"企業情報: {log['company_info']}")
                log_lines.append(f"所要時間: {log['duration_seconds']:.1f}秒")
                log_lines.append("")
                log_lines.append("[プロンプト]")
                log_lines.append("-" * 80)
                log_lines.append(log['prompt'])
                log_lines.append("")
                log_lines.append("[応答]")
                log_lines.append("-" * 80)
                log_lines.append(log['response'])
                log_lines.append("")
                log_lines.append("[検証結果]")
                log_lines.append("-" * 80)
                log_lines.append(str(log['validation']))
                log_lines.append("")
                log_lines.append("")

            log_text = "\n".join(log_lines)

            st.download_button(
                label="💾 prompt_log.txt をダウンロード",
                data=log_text,
                file_name="prompt_log.txt",
                mime="text/plain",
                key="download_log"
            )

# フッター
st.markdown("---")
st.markdown("*Powered by Snowflake Cortex Agent*")
