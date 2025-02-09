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

# 1. 환경 설정
if (-not (Test-Path "venv")) {
    python -m venv venv
}
. .\venv\Scripts\Activate.ps1

# 2. 의존성 설치
python -m pip install --upgrade pip
pip install -r requirements.txt

# 3. PYTHONPATH 설정
$env:PYTHONPATH = "$PWD;$PWD\src"

# 4. 환경 변수 파일 생성
@"
FLASK_APP=src.app:create_app
FLASK_ENV=development
DATABASE_URL=postgresql://user:password@localhost:5433/text_to_sql
REDIS_URL=redis://localhost:6379/0
LANGFLOW_API_URL=http://localhost:7860
"@ | Out-File -FilePath ".env" -Encoding UTF8

# 환경 변수 로드
. .\scripts\utils\env.ps1

# Docker 네트워크 생성
if (-not (docker network ls --filter name=text-to-sql-network -q)) {
    docker network create text-to-sql-network
}

# 기존 컨테이너 정리
docker-compose down -v

# 이미지 빌드
docker-compose build

# 서비스 시작
docker-compose up -d

# 상태 확인
Write-Host "Waiting for services to be ready..."
Start-Sleep -Seconds 30

# 헬스체크
$services = @(
    @{Url="http://localhost:5433"; Name="Database"},
    @{Url="http://localhost:6379"; Name="Redis"},
    @{Url="http://localhost:7860/health"; Name="Langflow"},
    @{Url="http://localhost:5000/health"; Name="Backend"},
    @{Url="http://localhost:3000"; Name="Frontend"}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.Url -Method GET
        Write-Host "$($service.Name) is ready!"
    } catch {
        Write-Host "$($service.Name) is not responding. Please check logs."
        docker-compose logs $service.Name.ToLower()
    }
}

# 7. Alembic 초기화 (처음 한 번만)
if (-not (Test-Path "migrations")) {
    Write-Host "Initializing alembic..."
    alembic init migrations
    
    # env.py 생성
    New-Item -ItemType Directory -Force -Path "migrations"
    $env_py = @"
from logging.config import fileConfig
from sqlalchemy import engine_from_config
from sqlalchemy import pool
from alembic import context
from src.models.user import Base

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
"@
    $env_py | Out-File -FilePath "migrations\env.py" -Encoding UTF8
    
    # alembic.ini 설정
    (Get-Content alembic.ini) -replace 'sqlalchemy.url = driver://user:pass@localhost/dbname', 'sqlalchemy.url = postgresql://user:password@localhost:5434/text_to_sql' | Set-Content alembic.ini
}

# 8. 마이그레이션 실행 (순서 중요)
Write-Host "Running database migrations..."
alembic revision --autogenerate -m "initial"
alembic upgrade head

# 9. 프론트엔드 초기화 및 실행
Write-Host "Setting up frontend..."
if (-not (Test-Path "frontend")) {
    Write-Host "Creating frontend directory..."
    New-Item -ItemType Directory -Path "frontend"
    Push-Location frontend
    
    # React 프로젝트 초기화
    npx create-react-app .
    
    # 필요한 패키지 설치
    npm install @material-ui/core @material-ui/icons axios react-router-dom
    
    Pop-Location
}

# 프론트엔드 실행
Push-Location frontend
npm install
npm run build
Start-Process npm -ArgumentList "start" -NoNewWindow
Pop-Location

# 10. 백엔드 실행
Write-Host "Starting backend..."
Start-Process python -ArgumentList "-m flask run --host=0.0.0.0 --port=5000" -NoNewWindow

# 11. Langflow 초기화
Write-Host "Initializing Langflow..."
python src/scripts/init_langflow.py 