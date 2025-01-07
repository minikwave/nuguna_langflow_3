import requests
from app.config import Config

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
