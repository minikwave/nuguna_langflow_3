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

# 5. Docker 컨테이너 실행
docker-compose down -v
docker-compose up -d db redis langflow

# 6. 데이터베이스 준비 대기
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

# 7. Alembic 초기화 (처음 한 번만)
if (-not (Test-Path "migrations")) {
    Write-Host "Initializing alembic..."
    alembic init migrations
    
    # env.py 수정
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
    (Get-Content alembic.ini) -replace 'sqlalchemy.url = driver://user:pass@localhost/dbname', 'sqlalchemy.url = postgresql://user:password@localhost:5433/text_to_sql' | Set-Content alembic.ini
}

# 8. 마이그레이션 실행
Write-Host "Running database migrations..."
alembic revision --autogenerate -m "initial"
alembic upgrade head

# 9. 초기 데이터 생성
Write-Host "Seeding database..."
python scripts/seed_database.py

# 10. Langflow 초기화
Write-Host "Initializing Langflow..."
python src/scripts/init_langflow.py

# 11. 백엔드 시작
Write-Host "Starting backend..."
python -m flask run --host=0.0.0.0 --port=5000 