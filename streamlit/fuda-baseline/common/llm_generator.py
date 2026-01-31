"""
LLM生成モジュール
Cortex Agent REST APIを使用してFact Sheetと提案書を生成
"""

import json
import os
from typing import Optional

# Streamlit in Snowflake環境用
try:
    import _snowflake
    SIS_AVAILABLE = True
except ImportError:
    SIS_AVAILABLE = False

from .snowflake_util import SnowflakeConnection


class CortexAgentClient:
    """Snowflake Cortex Agent クライアント"""

    def __init__(
        self,
        snowflake_connection: SnowflakeConnection,
        database: str,
        schema: str,
        agent_name: str,
        timeout_ms: Optional[int] = None,
    ):
        """
        Args:
            snowflake_connection: Snowflake接続インスタンス
            database: Agentが存在するデータベース名
            schema: Agentが存在するスキーマ名
            agent_name: Agent名
            timeout_ms: タイムアウト時間（ミリ秒）、Noneで無制限
        """
        self.snowflake_connection = snowflake_connection
        self.session = snowflake_connection.get_client()
        self.database = database
        self.schema = schema
        self.agent_name = agent_name
        self.timeout_ms = timeout_ms  # Noneで無制限
        self.thread_id = None  # スレッドID

    def create_thread(self, origin_application: str = "fdua-baseline", on_event=None) -> str:
        """スレッドを作成する

        Args:
            origin_application: アプリケーション名（16バイト以内）
            on_event: イベントコールバック関数

        Returns:
            str: スレッドID

        Raises:
            Exception: スレッド作成エラー時
        """
        if SIS_AVAILABLE:
            return self._create_thread_sis(origin_application, on_event)
        else:
            raise Exception(
                "Thread creation is only supported in Streamlit in Snowflake environment."
            )

    def _create_thread_sis(self, origin_application: str, on_event=None) -> str:
        """SiS環境でスレッドを作成する

        Args:
            origin_application: アプリケーション名
            on_event: イベントコールバック関数

        Returns:
            str: スレッドID
        """
        endpoint = "/api/v2/cortex/threads"
        request_body = {
            "origin_application": origin_application
        }

        if on_event:
            on_event("thread_create_start", {"origin_application": origin_application})

        try:
            resp = _snowflake.send_snow_api_request(
                "POST",
                endpoint,
                {},  # headers
                {},  # params
                request_body,
                None,  # request_guid
                self.timeout_ms
            )

            # レスポンスからスレッドIDを取得
            if isinstance(resp, dict) and 'content' in resp:
                content = resp['content']
                if isinstance(content, str):
                    thread_id = json.loads(content) if content.startswith('{') else content
                else:
                    thread_id = content
            elif isinstance(resp, str):
                thread_id = json.loads(resp) if resp.startswith('{') else resp
            else:
                thread_id = resp

            # スレッドIDを保存
            self.thread_id = thread_id

            if on_event:
                on_event("thread_created", {"thread_id": thread_id})

            return thread_id

        except Exception as e:
            if on_event:
                on_event("error", {"error": str(e)})
            raise Exception(f"Failed to create thread: {str(e)}")

    def call_agent(self, query: str, on_event=None) -> dict:
        """Cortex Agentを呼び出す

        Args:
            query: ユーザークエリテキスト
            on_event: イベントコールバック関数 (event_type: str, data: dict) -> None

        Returns:
            dict: パース済みレスポンス

        Raises:
            Exception: リクエストエラー時
        """
        # SiS環境の場合、_snowflake.send_snow_api_request()を使用
        if SIS_AVAILABLE:
            return self._call_agent_sis(query, on_event)
        else:
            # ローカル環境では未サポート
            raise Exception(
                "CortexAgentClient is only supported in Streamlit in Snowflake environment. "
                "Please deploy to Snowflake to use this feature."
            )

    def _call_agent_sis(self, query: str, on_event=None, use_direct_endpoint: bool = False) -> dict:
        """
        SiS環境でCortex Agentを呼び出す

        Args:
            query: ユーザークエリテキスト
            on_event: イベントコールバック関数
            use_direct_endpoint: True の場合 /api/v2/cortex/agent:run を使用

        Returns:
            dict: パース済みレスポンス
        """
        # エンドポイントパス
        if use_direct_endpoint:
            # 直接実行エンドポイント
            endpoint = "/api/v2/cortex/agent:run"
        else:
            # 既存エージェント経由エンドポイント
            endpoint = f"/api/v2/databases/{self.database}/schemas/{self.schema}/agents/{self.agent_name}:run"

        # リクエストボディ
        request_body = {
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": query
                        }
                    ]
                }
            ]
        }

        # スレッドIDがある場合は追加
        if self.thread_id:
            request_body["thread_id"] = self.thread_id

        # 進捗コールバック
        if on_event:
            on_event("request_start", {"endpoint": endpoint, "query_length": len(query)})

        # API呼び出し
        try:
            # ストリーミングを明示的に要求
            headers = {
                "Accept": "text/event-stream",
                "Content-Type": "application/json"
            }

            resp = _snowflake.send_snow_api_request(
                "POST",
                endpoint,
                headers,  # headers
                {},  # params
                request_body,
                None,  # request_guid
                self.timeout_ms
            )

            if on_event:
                on_event("response_received", {"response_type": str(type(resp))})

            # レスポンスがすでに辞書の場合はそのまま返す
            if isinstance(resp, dict):
                if on_event:
                    on_event("response_parsed", {"keys": list(resp.keys())})
                return resp

            # 文字列の場合はJSONパース
            if isinstance(resp, str):
                parsed = json.loads(resp)
                if on_event:
                    on_event("response_parsed", {"keys": list(parsed.keys())})
                return parsed

            # バイト列の場合
            if isinstance(resp, bytes):
                parsed = json.loads(resp.decode('utf-8'))
                if on_event:
                    on_event("response_parsed", {"keys": list(parsed.keys())})
                return parsed

            raise Exception(f"Unexpected response type: {type(resp)}")

        except Exception as e:
            if on_event:
                on_event("error", {"error": str(e)})
            raise Exception(f"Failed to call Cortex Agent: {str(e)}")


def generate_fact_sheet(
    snowflake_connection: SnowflakeConnection,
    agent_name: str,
    company_info: dict,
    financial_data,
    financial_metrics: dict,
    pdf_full_text: str
) -> dict:
    """
    Fact Sheet生成（Cortex Agent）

    Args:
        snowflake_connection: Snowflake接続
        agent_name: Cortex Agent名
        company_info: 企業情報
        financial_data: 財務データDataFrame
        financial_metrics: 計算された財務指標
        pdf_full_text: PDF全文

    Returns:
        dict: Fact Sheet（JSON）
    """
    from ..config.prompts import format_fact_sheet_prompt

    client = CortexAgentClient(
        snowflake_connection,
        "FDUA_COMPETITION",
        "PUBLIC",
        agent_name
    )

    # プロンプト構築
    query = format_fact_sheet_prompt(
        company_info,
        financial_data,
        financial_metrics,
        pdf_full_text
    )

    # Agent呼び出し
    response = client.call_agent(query)

    # JSON固定スキーマでパース
    return parse_fact_sheet_response(response)


def generate_proposal(
    snowflake_connection: SnowflakeConnection,
    agent_name: str,
    fact_sheet: dict,
    company_info: dict
) -> str:
    """
    提案書生成（Cortex Agent）

    Args:
        snowflake_connection: Snowflake接続
        agent_name: Cortex Agent名
        fact_sheet: Fact Sheet（JSON）
        company_info: 企業情報

    Returns:
        str: 提案書本文（Markdown）
    """
    from ..config.prompts import format_proposal_prompt

    client = CortexAgentClient(
        snowflake_connection,
        "FDUA_COMPETITION",
        "PUBLIC",
        agent_name
    )

    # プロンプト構築（評価基準（5つの視点）を考慮）
    query = format_proposal_prompt(fact_sheet, company_info)

    # Agent呼び出し
    response = client.call_agent(query)

    # Markdown形式で返却
    return extract_proposal_text(response)


def parse_fact_sheet_response(response: dict) -> dict:
    """
    Fact Sheetレスポンスをパース

    Args:
        response: Cortex Agent APIレスポンス

    Returns:
        dict: パースされたFact Sheet
    """
    import re

    try:
        # Extract text from response
        content = response.get('message', {}).get('content', [])
        if not content:
            raise ValueError("Empty response from Cortex Agent")

        text = content[0].get('text', '')

        # Try to extract JSON from text
        # Look for JSON object between ```json and ``` or just find the object
        json_match = re.search(r'```json\s*(.*?)\s*```', text, re.DOTALL)
        if json_match:
            json_str = json_match.group(1)
        else:
            # Try to find JSON object directly
            json_match = re.search(r'\{.*\}', text, re.DOTALL)
            if json_match:
                json_str = json_match.group(0)
            else:
                # If no JSON found, assume entire text is JSON
                json_str = text

        # Parse JSON
        fact_sheet = json.loads(json_str)
        return fact_sheet

    except (json.JSONDecodeError, ValueError) as e:
        print(f"Warning: Failed to parse Fact Sheet response: {e}")
        # Return a default structure
        return {
            "企業概要": "",
            "外部環境分析": "",
            "地域特性": "",
            "財務分析": {
                "売上推移": "",
                "利益率": "",
                "CF状況": ""
            },
            "課題仮説": [],
            "成長機会": [],
            "リスク": [],
            "施策候補": [],
            "期待効果": ""
        }


def extract_proposal_text(response: dict) -> str:
    """
    提案書テキストを抽出

    Args:
        response: Cortex Agent APIレスポンス

    Returns:
        str: 提案書本文（Markdown）
    """
    import re

    try:
        # Extract text from response
        content = response.get('message', {}).get('content', [])
        if not content:
            raise ValueError("Empty response from Cortex Agent")

        text = content[0].get('text', '')

        # Remove code fences if present
        text = re.sub(r'```markdown\s*', '', text)
        text = re.sub(r'```\s*$', '', text)

        return text.strip()

    except (ValueError, KeyError) as e:
        print(f"Warning: Failed to extract proposal text: {e}")
        return ""
