# init.ps1

# 1. 환경 확인
Write-Host "Checking environment..."

# 메인 애플리케이션 환경 설정 (Python 3.13)
Write-Host "Setting up main application..."
if (-not (Test-Path "venv")) {
    py -3.13 -m venv venv
}
. .\venv\Scripts\activate

# 의존성 설치 (순서 중요)
pip install --upgrade pip
pip install wheel setuptools
pip install -r requirements.txt

# PYTHONPATH 설정
$env:PYTHONPATH = "$PWD"

# 2. Docker 컨테이너 실행 (Langflow 포함)
Write-Host "Starting Docker containers..."
docker-compose down -v
docker-compose up -d db redis langflow

# 3. 데이터베이스 연결 대기
$retries = 0
while ($retries -lt 30) {
    try {
        $conn = New-Object System.Net.Sockets.TcpClient
        $conn.Connect("localhost", 5433)
        $conn.Close()
        Write-Host "PostgreSQL is ready!"
        break
    }
    catch {
        $retries++
        Write-Host "Waiting for PostgreSQL... ($retries/30)"
        Start-Sleep -Seconds 1
    }
}

# 4. 데이터베이스 마이그레이션
Write-Host "Running database migrations..."
alembic upgrade head

# 5. 초기 데이터 생성
Write-Host "Seeding database..."
python scripts/seed_database.py

# 6. Langflow 시작
Write-Host "Starting Langflow..."
Start-Process -FilePath "langflow_venv\Scripts\python.exe" -ArgumentList "src\scripts\run_langflow.py"

# Langflow 준비 대기
$retries = 0
while ($retries -lt 30) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:7860/health" -Method GET
        if ($response.StatusCode -eq 200) {
            Write-Host "Langflow is ready!"
            break
        }
    }
    catch {
        $retries++
        Write-Host "Waiting for Langflow... ($retries/30)"
        Start-Sleep -Seconds 1
    }
}

# 7. Langflow 초기화
Write-Host "Initializing Langflow..."
python src/scripts/init_langflow.py

# 8. 백엔드 시작
Write-Host "Starting backend..."
python -m flask run --host=0.0.0.0 --port=5000 