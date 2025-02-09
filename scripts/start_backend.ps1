Write-Host "Starting backend..."

# 1. 환경 변수 설정
$env:FLASK_APP = "src.app:create_app()"
$env:FLASK_ENV = "development"
$env:PYTHONPATH = "$PWD;$PWD\src"

# 2. Flask 실행
python -m flask run --host=0.0.0.0 --port=5000 