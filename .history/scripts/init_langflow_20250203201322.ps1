Write-Host "Initializing Langflow..."

# 1. 환경 변수 설정
$env:PYTHONPATH = "$PWD;$PWD\src"

# 2. Langflow 초기화
python src/scripts/init_langflow.py 