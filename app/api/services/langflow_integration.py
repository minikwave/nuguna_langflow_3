import json
import requests

LANGFLOW_API_BASE = "http://localhost:7860/api/v1"

def load_workflow(workflow_id: str):
    """Langflow에서 워크플로우 로드"""
    response = requests.get(f"{LANGFLOW_API_BASE}/workflows/{workflow_id}")
    if response.status_code == 200:
        return response.json()
    return {"error": "Failed to load workflow"}

def execute_workflow(workflow_data: dict):
    """워크플로우 실행"""
    response = requests.post(f"{LANGFLOW_API_BASE}/workflows/execute", json=workflow_data)
    if response.status_code == 200:
        return response.json()
    return {"error": "Workflow execution failed"}
