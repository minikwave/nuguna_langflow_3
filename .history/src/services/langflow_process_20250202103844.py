import subprocess
import time
import requests
from pathlib import Path
from src.config import Config

class LangflowProcessManager:
    def __init__(self):
        self.process = None
        self.venv_path = Path(__file__).parent.parent.parent / "langflow_venv"
        self.python_path = self.venv_path / "Scripts" / "python.exe"
        
    async def start(self):
        """Langflow 프로세스 시작"""
        if not self.process:
            self.process = subprocess.Popen([
                str(self.python_path),
                "src/scripts/run_langflow.py"
            ])
            await self._wait_for_startup()
    
    async def _wait_for_startup(self):
        """Langflow 서버 준비 대기"""
        retries = 0
        while retries < 30:
            try:
                response = requests.get(f"{Config.LANGFLOW_API_URL}/health")
                if response.status_code == 200:
                    return
            except:
                pass
            time.sleep(1)
            retries += 1
        raise Exception("Langflow 서버 시작 실패")
    
    def stop(self):
        """Langflow 프로세스 종료"""
        if self.process:
            self.process.terminate()
            self.process = None 