import os
import json
from asyncio import Lock
from typing import Dict

FLOWS_DIR = "data/flows"

class FlowManager:
    def __init__(self):
        self._locks: Dict[str, Lock] = {}
        
    async def get_flow_lock(self, flow_id: str) -> Lock:
        if flow_id not in self._locks:
            self._locks[flow_id] = Lock()
        return self._locks[flow_id]

def save_flow(user_id, flow_name, flow_content):
    """사용자별 Flow를 저장."""
    user_dir = os.path.join(FLOWS_DIR, user_id)
    os.makedirs(user_dir, exist_ok=True)
    file_path = os.path.join(user_dir, f"{flow_name}.json")
    with open(file_path, "w") as f:
        json.dump(flow_content, f)
    return file_path

def load_flow(user_id, flow_name):
    """사용자별 Flow를 로드."""
    try:
        file_path = os.path.join(FLOWS_DIR, user_id, f"{flow_name}.json")
        with open(file_path, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return {"error": f"Flow {flow_name} not found for user {user_id}."}

def list_flows(user_id):
    """사용자가 생성한 모든 Flow 목록 반환."""
    user_dir = os.path.join(FLOWS_DIR, user_id)
    if not os.path.exists(user_dir):
        return []
    return [f[:-5] for f in os.listdir(user_dir) if f.endswith(".json")]

def delete_flow(user_id, flow_name):
    """사용자 Flow 삭제."""
    try:
        os.remove(os.path.join(FLOWS_DIR, user_id, f"{flow_name}.json"))
    except FileNotFoundError:
        pass
