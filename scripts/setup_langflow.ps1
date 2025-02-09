# Langflow 전용 Python 3.11 환경 설정
Write-Host "Setting up Langflow environment..."

# Python 3.11 전용 가상환경 생성
py -3.11 -m venv langflow_venv
. .\langflow_venv\Scripts\activate

# Langflow 의존성 설치
pip install --upgrade pip
pip install -r requirements.langflow.txt

# 비활성화
deactivate 