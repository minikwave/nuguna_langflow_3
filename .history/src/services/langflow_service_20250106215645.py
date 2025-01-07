import requests
from app.config import Config
import os

def call_langflow(user_input, session_id="default_session"):
    """
    Langflow API에 사용자 입력을 전달하여 SQL 쿼리 또는 기타 작업 수행.
    """
    try:
        payload = {
            "inputs": {"text": user_input},
            "session_id": session_id
        }
        response = requests.post(f"{Config.LANGFLOW_API_URL}/api/v1/run", json=payload)
        response.raise_for_status()
        return response.json().get("query", "")
    except requests.exceptions.RequestException as e:
        return f"Langflow 호출 오류: {str(e)}"
    
def call_playground(input_text, session_id="default_session", flow_id=None, api_key=None):
    """
    Langflow Playground 호출.
    """
    try:
        payload = {
            "input_value": input_text,
            "session_id": session_id,
            "output_type": "chat",
            "input_type": "chat"
        }

        headers = {}
        if api_key:
            headers["x-api-key"] = api_key

        api_url = f"{Config.LANGFLOW_API_URL}/api/v1/run/{flow_id}"
        response = requests.post(api_url, json=payload, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e)}

def enable_auto_saving():
    """Langflow Auto-Saving 활성화."""
    os.environ["LANGFLOW_AUTO_SAVING"] = "true"

def disable_auto_saving():
    """Langflow Auto-Saving 비활성화."""
    os.environ["LANGFLOW_AUTO_SAVING"] = "false"