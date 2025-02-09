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
