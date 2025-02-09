Write-Host "Resetting backend..."

# 1. Clean
Write-Host "Cleaning backend..."
if (Test-Path "__pycache__") {
    Remove-Item "__pycache__" -Recurse -Force
    Write-Host "Cleaned Python cache"
}

# 2. app.py 생성
$app_py = @"
from flask import Flask
from flask_cors import CORS
from src.models import Base
from sqlalchemy import create_engine

def create_app():
    app = Flask(__name__)
    CORS(app)
    
    app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://user:password@localhost:5434/text_to_sql'
    
    # 데이터베이스 초기화
    engine = create_engine(app.config['SQLALCHEMY_DATABASE_URI'])
    Base.metadata.bind = engine
    
    return app
"@
Set-Content -Path "src/app.py" -Value $app_py

# 3. Start
Write-Host "Starting backend..."
$env:FLASK_APP = "src.app:create_app"
$env:FLASK_ENV = "development"
$env:PYTHONPATH = "$PWD;$PWD\src"

Start-Process python -ArgumentList "-m flask run --host=0.0.0.0 --port=5000" -NoNewWindow 

# requirements.txt에 필요한 의존성 추가
$requirements = @"
flask==2.0.1
flask-cors==3.0.10
sqlalchemy==1.4.23
alembic==1.7.1
psycopg2==2.9.1
python-dotenv==0.19.0
gunicorn==20.1.0
uvicorn==0.15.0
langflow==0.4.0
redis==4.3.4
requests==2.26.0
"@
Set-Content -Path "requirements.txt" -Value $requirements

# Visual C++ 빌드 도구 설치 (psycopg2 컴파일에 필요)
choco install visualstudio2019buildtools -y
choco install visualstudio2019-workload-vctools -y

# pip 업그레이드 및 의존성 설치
python -m pip install --upgrade pip
pip install -r requirements.txt 