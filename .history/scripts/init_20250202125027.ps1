# init.ps1

# 1. 환경 확인
Write-Host "Checking environment..."

# Docker 실행 확인
try {
    docker version | Out-Null
} catch {
    Write-Host "Docker is not running. Please start Docker Desktop first."
    exit 1
}

# 로그 디렉토리 생성
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs"
}

# 메인 애플리케이션 환경 설정 (Python 3.13)
Write-Host "Setting up main application..."
if (-not (Test-Path "venv")) {
    py -3.13 -m venv venv
}
. .\venv\Scripts\activate

# 의존성 설치 (순서 중요)
Write-Host "Installing dependencies..."
python -m pip install --upgrade pip
python -m pip install --no-cache-dir wheel setuptools
python -m pip install --no-cache-dir gunicorn==20.1.0
python -m pip install --no-cache-dir -r requirements.txt

# 의존성 설치 후 확인
Write-Host "Verifying installations..."
$packages = @(
    "flask",
    "sqlalchemy",
    "alembic",
    "python-dotenv",
    "langflow"
)

foreach ($package in $packages) {
    try {
        python -c "import $package; print(f'$package version: {$package.__version__}')"
    } catch {
        Write-Host "Warning: $package import failed"
        exit 1
    }
}

# PYTHONPATH 설정
$env:PYTHONPATH = "$PWD\src"

# 환경 변수 설정
$env:FLASK_APP = "src.app:create_app()"
$env:FLASK_ENV = "development"
$env:DATABASE_URL = "postgresql://user:password@localhost:5433/text_to_sql"
$env:REDIS_URL = "redis://localhost:6379/0"
$env:LANGFLOW_API_URL = "http://localhost:7860"

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
python -m alembic upgrade head

# 5. 초기 데이터 생성
Write-Host "Seeding database..."
python scripts/seed_database.py

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

# 6. Langflow 초기화
Write-Host "Initializing Langflow..."
python src/scripts/init_langflow.py

# 7. 백엔드 시작
Write-Host "Starting backend..."
python -m flask run --host=0.0.0.0 --port=5000 --debug 