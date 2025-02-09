Write-Host "Setting up database..."

# 1. models/__init__.py 수정
$models_init = @"
from .user import User, Base

__all__ = ['User', 'Base']
"@
Set-Content -Path "src/models/__init__.py" -Value $models_init

# 2. Alembic 초기화
if (-not (Test-Path "migrations")) {
    Write-Host "Initializing alembic..."
    alembic init migrations
    
    # env.py 설정
    Copy-Item "scripts/templates/env.py" -Destination "migrations/env.py" -Force
    
    # alembic.ini 설정
    (Get-Content alembic.ini) -replace 'sqlalchemy.url = driver://user:pass@localhost/dbname', 'sqlalchemy.url = postgresql://user:password@localhost:5433/text_to_sql' | Set-Content alembic.ini
}

# 3. 마이그레이션 실행
Write-Host "Running migrations..."
alembic revision --autogenerate -m "initial"
alembic upgrade head

# 4. 초기 데이터 생성
Write-Host "Seeding database..."
python scripts/seed_database.py 