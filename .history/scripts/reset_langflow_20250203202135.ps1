Write-Host "Resetting Langflow..."

# 1. Clean
Write-Host "Cleaning Langflow..."
if (Test-Path "src/services/langflow/__pycache__") {
    Remove-Item "src/services/langflow/__pycache__" -Recurse -Force
}

# 2. Langflow 서비스 구조 생성
$process_manager = @"
import subprocess
import time
import requests
import os

class LangflowProcessManager:
    def __init__(self):
        self.process = None
        self.api_url = os.getenv('LANGFLOW_API_URL', 'http://localhost:7860')
    
    async def start(self):
        if not self.is_running():
            self.process = subprocess.Popen(['langflow', 'run'], 
                                         stdout=subprocess.PIPE,
                                         stderr=subprocess.PIPE)
            await self.wait_for_startup()
    
    def is_running(self):
        try:
            response = requests.get(f"{self.api_url}/health")
            return response.status_code == 200
        except:
            return False
    
    async def wait_for_startup(self, timeout=60):
        retries = 0
        while retries < timeout:
            if self.is_running():
                return
            time.sleep(1)
            retries += 1
        raise Exception("Failed to start Langflow")
"@
New-Item -ItemType Directory -Path "src/services/langflow/process" -Force
Set-Content -Path "src/services/langflow/process/__init__.py" -Value "from .manager import LangflowProcessManager"
Set-Content -Path "src/services/langflow/process/manager.py" -Value $process_manager

# 3. Initialize
Write-Host "Initializing Langflow..."
$env:PYTHONPATH = "$PWD;$PWD\src"
python src/scripts/init_langflow.py 

# Langflow 및 관련 패키지 설치
pip install langflow langchain openai python-dotenv 