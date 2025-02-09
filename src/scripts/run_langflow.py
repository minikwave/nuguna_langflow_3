import os
import sys
from pathlib import Path

# Langflow 전용 venv의 Python 사용
VENV_PATH = Path(__file__).parent.parent.parent / "langflow_venv"
PYTHON_PATH = VENV_PATH / "Scripts" / "python.exe"

def run_langflow():
    """Langflow 서버 실행"""
    os.environ["PYTHONPATH"] = str(VENV_PATH / "Lib" / "site-packages")
    os.execv(str(PYTHON_PATH), [str(PYTHON_PATH), "-m", "langflow", "run"])

if __name__ == "__main__":
    run_langflow() 