import subprocess
import time
import requests
from pathlib import Path
import os

class LangflowProcessManager:
    def __init__(self):
        self.process = None
        self.api_url = os.getenv('LANGFLOW_API_URL', 'http://localhost:7860')
        
    async def start(self):
        """Langflow 프로세스 시작"""
        if not self.process:
            try:
                # Docker 컨테이너에서 실행 중인지 확인
                response = requests.get(f"{self.api_url}/health")
                if response.status_code == 200:
                    print("Langflow is already running in Docker")
                    return
            except:
                print("Starting Langflow process...")
                self.process = subprocess.Popen([
                    "langflow",
                    "run",
                    "--host", "0.0.0.0",
                    "--port", "7860"
                ])
                await self._wait_for_startup()
    
    async def _wait_for_startup(self):
        retries = 0
        while retries < 30:
            try:
                response = requests.get(f"{self.api_url}/health")
                if response.status_code == 200:
                    print("Langflow is ready!")
                    return
            except:
                pass
            time.sleep(1)
            retries += 1
        raise Exception("Failed to start Langflow") 