import os
import httpx
from typing import Dict, Any, Optional, List
import aiohttp
from src.config import Config
from aiohttp import ClientSession

class LangflowClient:
    def __init__(self):
        self.base_url = Config.LANGFLOW_API_URL
        self.username = Config.LANGFLOW_SUPERUSER
        self.password = Config.LANGFLOW_SUPERUSER_PASSWORD
        self.headers = {
            "Content-Type": "application/json"
        }
        self.session = None

    async def __aenter__(self):
        self.session = ClientSession()
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()

    async def login(self) -> str:
        """Langflow 로그인 및 토큰 획득"""
        async with aiohttp.ClientSession(headers=self.headers) as session:
            async with session.post(
                f"{self.base_url}/api/v1/login",
                json={
                    "username": self.username,
                    "password": self.password
                }
            ) as response:
                if response.status != 200:
                    raise Exception(f"Langflow 로그인 실패: {await response.text()}")
                data = await response.json()
                token = data["access_token"]
                self.headers["Authorization"] = f"Bearer {token}"
                return token

    async def create_component(self, component_data: Dict[str, Any]) -> Dict[str, Any]:
        """커스텀 컴포넌트 생성"""
        async with aiohttp.ClientSession(headers=self.headers) as session:
            async with session.post(
                f"{self.base_url}/api/v1/custom_components",
                json=component_data
            ) as response:
                if response.status != 201:
                    raise Exception(f"컴포넌트 생성 실패: {await response.text()}")
                return await response.json()

    async def validate_flow(self, flow_data: Dict[str, Any]) -> Dict[str, Any]:
        """워크플로우 유효성 검증"""
        async with aiohttp.ClientSession(headers=self.headers) as session:
            async with session.post(
                f"{self.base_url}/api/v1/validate",
                json=flow_data
            ) as response:
                return await response.json()

    async def get_components(self) -> List[Dict[str, Any]]:
        """사용 가능한 컴포넌트 목록 조회"""
        async with aiohttp.ClientSession(headers=self.headers) as session:
            async with session.get(
                f"{self.base_url}/api/v1/components"
            ) as response:
                return await response.json()

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

    async def execute_flow(self, flow_id: str, inputs: dict):
        """Langflow API 호출"""
        async with self.session.post(
            f"{self.base_url}/api/v1/flows/{flow_id}/execute",
            json=inputs
        ) as response:
            return await response.json()

    async def get_flow(self, flow_id: str) -> Optional[Dict[str, Any]]:
        """Get flow details by ID"""
        response = await self.session.get(f'/api/v1/flows/{flow_id}')
        if response.status_code == 404:
            return None
        response.raise_for_status()
        return response.json()

    async def list_flows(self) -> Dict[str, Any]:
        """List all available flows"""
        response = await self.session.get('/api/v1/flows/')
        response.raise_for_status()
        return response.json()

    async def delete_flow(self, flow_id: str) -> bool:
        """Delete a flow by ID"""
        response = await self.session.delete(f'/api/v1/flows/{flow_id}')
        return response.status_code == 204 