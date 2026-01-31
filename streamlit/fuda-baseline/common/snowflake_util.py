from logging import getLogger
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark.exceptions import SnowparkSessionException
import streamlit as st
import os

logger = getLogger(__name__)


class SnowflakeConnection:
    def __init__(self):
        self.session = None
        self.oauth_session_path = "/snowflake/session/token"

    def get_active_session(self):
        try:
            self.session = get_active_session()
        except SnowparkSessionException as e:
            logger.warning(f"Snowflakeクライアントの取得に失敗: {e}")
        return self.session

    def get_session_in_local(self):
        try:
            secrets = st.secrets["snowflake"]
            connection_parameters = {
                "user": secrets.get("user"),
                "private_key_file": secrets.get("private_key_file_path"),
                "account": secrets.get("account"),
                "role": secrets.get("role"),
                "warehouse": secrets.get("warehouse"),
                "database": secrets.get("database"),
                "schema": secrets.get("schema"),
            }
            self.session = Session.builder.configs(connection_parameters).create()
        except Exception as e:
            logger.warning(f"Snowflakeクライアントの取得に失敗: {e}")
        return self.session

    def get_session_in_spcs(self):
        try:
            if os.path.isfile(self.oauth_session_path):
                connection_parameters = {
                    "protocol": "https",
                    "account": os.getenv("SNOWFLAKE_ACCOUNT"),
                    "host": os.getenv("SNOWFLAKE_HOST"),
                    "authenticator": "oauth",
                    "token": open("/snowflake/session/token", "r").read(),
                    "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE"),
                    "database": os.getenv("SNOWFLAKE_DATABASE"),
                    "schema": os.getenv("SNOWFLAKE_SCHEMA"),
                    "client_session_keep_alive": True,
                }
            else:
                connection_parameters = {
                    "account": os.getenv("SNOWFLAKE_ACCOUNT"),
                    "user": os.getenv("SNOWFLAKE_USER"),
                    "password": os.getenv("SNOWFLAKE_PASSWORD"),
                    "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE"),
                    "database": os.getenv("SNOWFLAKE_DATABASE"),
                    "schema": os.getenv("SNOWFLAKE_SCHEMA"),
                    "client_session_keep_alive": True,
                }
            self.session = Session.builder.configs(connection_parameters).create()
        except Exception as e:
            logger.warning(f"Snowflakeクライアントの取得に失敗: {e}")
        return self.session

    def get_client(self):
        try:
            self.get_active_session()
            if self.session is None:
                self.get_session_in_local()
            if self.session is None:
                self.get_session_in_spcs()
        except Exception as e:
            st.error(f"Snowflakeクライアントの取得に失敗: {e}")
        if self.session is None:
            raise Exception("Snowflakeクライアントの取得に失敗しました")
        return self.session
