import requests

LANGFLOW_API_BASE = "http://localhost:7860/api/v1"

def execute_workflow(workflow_data: dict):
    """
    Langflow 워크플로우 실행 로직
    Args:
        workflow_data (dict): 실행할 워크플로우 JSON 데이터

    Returns:
        dict: 실행 결과 또는 오류 메시지
    """
    try:
        # Langflow 워크플로우 실행 API 호출
        response = requests.post(f"{LANGFLOW_API_BASE}/workflows/execute", json=workflow_data)
        if response.status_code == 200:
            return response.json()
        else:
            return {"status": "error", "message": response.text}
    except requests.exceptions.RequestException as e:
        return {"status": "error", "message": str(e)}

def load_workflow(workflow_id: str):
    """
    Langflow 워크플로우 로드 로직
    Args:
        workflow_id (str): 로드할 워크플로우 ID

    Returns:
        dict: 워크플로우 데이터 또는 오류 메시지
    """
    try:
        # Langflow 워크플로우 로드 API 호출
        response = requests.get(f"{LANGFLOW_API_BASE}/workflows/{workflow_id}")
        if response.status_code == 200:
            return response.json()
        else:
            return {"status": "error", "message": response.text}
    except requests.exceptions.RequestException as e:
        return {"status": "error", "message": str(e)}
