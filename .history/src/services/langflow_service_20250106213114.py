import requests
from app.config import Config

def call_langflow(user_input):
    """
    Langflow API에 사용자 입력을 전달하여 SQL 쿼리를 생성.
    """
    try:
        payload = {"inputs": {"text": user_input}}
        response = requests.post(f"{Config.LANGFLOW_API_URL}/api/infer", json=payload)
        response.raise_for_status()
        result = response.json().get("query", "")
        return result
    except requests.exceptions.RequestException as e:
        return f"Langflow 호출 오류: {str(e)}"
