import requests
from app.config import Config
import os
from typing import Dict, Any, Optional
import aiohttp
from .monitoring import MetricsCollector

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

def call_langflow_with_key(input_text, flow_id, session_id, api_key):
    """Langflow API 호출."""
    headers = {"x-api-key": api_key}
    payload = {
        "input_value": input_text,
        "session_id": session_id,
        "output_type": "chat",
        "input_type": "chat"
    }
    api_url = f"{Config.LANGFLOW_API_URL}/api/v1/run/{flow_id}"
    response = requests.post(api_url, json=payload, headers=headers)
    response.raise_for_status()
    return response.json()

class LangflowService:
    def __init__(self, metrics_collector: MetricsCollector):
        self.base_url = Config.LANGFLOW_API_URL
        self.metrics = metrics_collector
        self.session = None
        self.headers = {
            "Authorization": f"Bearer {Config.LANGFLOW_APPLICATION_TOKEN}"
        }

    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()

    async def execute_flow(
        self,
        flow_id: str,
        inputs: Dict[str, Any],
        timeout: int = 30
    ) -> Optional[Dict[str, Any]]:
        """Langflow 워크플로우 실행"""
        try:
            with self.metrics.sql_conversion_time.labels(
                flow_id=flow_id,
                status="success"
            ).time():
                async with self.session.post(
                    f"{self.base_url}/api/v1/flows/{flow_id}/execute",
                    json=inputs,
                    timeout=timeout
                ) as response:
                    if response.status == 200:
                        return await response.json()
                    else:
                        error_data = await response.json()
                        self.metrics.conversion_errors.labels(
                            error_type=error_data.get("error_type", "unknown")
                        ).inc()
                        return None
        except Exception as e:
            self.metrics.conversion_errors.labels(
                error_type=type(e).__name__
            ).inc()
            raise
