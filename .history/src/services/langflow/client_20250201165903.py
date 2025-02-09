import os
import httpx
from typing import Dict, Any, Optional
import aiohttp
from app.config import Config

class LangflowClient:
    def __init__(self):
        self.base_url = Config.LANGFLOW_API_URL
        self.client = httpx.AsyncClient(base_url=self.base_url, timeout=30.0)

    async def create_flow(self, flow_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new flow in Langflow"""
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/api/v1/flows",
                json=flow_data
            ) as response:
                if response.status != 201:
                    raise Exception(f"Flow 생성 실패: {await response.text()}")
                return await response.json()

    async def execute_flow(self, flow_id: str, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """Langflow 워크플로우 실행"""
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/api/v1/process/{flow_id}",
                json={"inputs": inputs}
            ) as response:
                if response.status != 200:
                    raise Exception(f"Langflow API 오류: {await response.text()}")
                return await response.json()

    async def get_flow(self, flow_id: str) -> Optional[Dict[str, Any]]:
        """Get flow details by ID"""
        response = await self.client.get(f'/api/v1/flows/{flow_id}')
        if response.status_code == 404:
            return None
        response.raise_for_status()
        return response.json()

    async def list_flows(self) -> Dict[str, Any]:
        """List all available flows"""
        response = await self.client.get('/api/v1/flows/')
        response.raise_for_status()
        return response.json()

    async def delete_flow(self, flow_id: str) -> bool:
        """Delete a flow by ID"""
        response = await self.client.delete(f'/api/v1/flows/{flow_id}')
        return response.status_code == 204

    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose() 