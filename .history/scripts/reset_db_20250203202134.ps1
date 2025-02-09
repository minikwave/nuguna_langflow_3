Write-Host "Resetting database..."

# 1. Clean
Write-Host "Cleaning database..."
try {
    alembic downgrade base
} catch {
    Write-Host "No migrations to roll back"
}

if (Test-Path "migrations/versions") {
    Remove-Item "migrations/versions/*" -Force
    Write-Host "Cleaned migration versions"
}

# 2. models/__init__.py 생성
$models_init = @"
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, Integer, String, DateTime
import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(120), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

__all__ = ['Base', 'User']
"@
Set-Content -Path "src/models/__init__.py" -Value $models_init

# 3. Setup
Write-Host "Setting up database..."
if (-not (Test-Path "migrations")) {
    Write-Host "Initializing alembic..."
    alembic init migrations
}

# 4. env.py 설정
$env_py = @"
from logging.config import fileConfig
from sqlalchemy import engine_from_config
from sqlalchemy import pool
from alembic import context
from src.models import Base

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
            connection=connection,
            target_metadata=target_metadata
        )
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
"@
Set-Content -Path "migrations/env.py" -Value $env_py -Encoding UTF8

# 5. alembic.ini 설정
(Get-Content alembic.ini) -replace 'sqlalchemy.url = driver://user:pass@localhost/dbname', 'sqlalchemy.url = postgresql://user:password@localhost:5433/text_to_sql' | Set-Content alembic.ini

# 6. 마이그레이션 실행
Write-Host "Running migrations..."
alembic revision --autogenerate -m "initial"
alembic upgrade head

# 7. 초기 데이터 생성
$seed_script = @"
from sqlalchemy import create_engine, text
from src.models import Base, User

def seed_database():
    engine = create_engine('postgresql://user:password@localhost:5433/text_to_sql')
    Base.metadata.create_all(engine)
    
    with engine.connect() as conn:
        # Check if admin user exists
        result = conn.execute(text("SELECT * FROM users WHERE username = 'admin'")).fetchone()
        if not result:
            conn.execute(text('''
                INSERT INTO users (username, email)
                VALUES ('admin', 'admin@example.com')
            '''))
            conn.commit()

if __name__ == '__main__':
    seed_database()
"@
Set-Content -Path "scripts/seed_database.py" -Value $seed_script

Write-Host "Seeding database..."
python scripts/seed_database.py

# PostgreSQL 클라이언트 설치 (처음 한 번만)
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PostgreSQL client..."
    choco install postgresql
} 