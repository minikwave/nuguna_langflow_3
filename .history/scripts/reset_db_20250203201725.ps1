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

# 2. Setup
Write-Host "Setting up database..."
if (-not (Test-Path "migrations")) {
    Write-Host "Initializing alembic..."
    alembic init migrations
    
    # env.py 설정
    Copy-Item "scripts/templates/env.py" -Destination "migrations/env.py" -Force
    
    # alembic.ini 설정
    (Get-Content alembic.ini) -replace 'sqlalchemy.url = driver://user:pass@localhost/dbname', 'sqlalchemy.url = postgresql://user:password@localhost:5433/text_to_sql' | Set-Content alembic.ini
}

Write-Host "Running migrations..."
alembic revision --autogenerate -m "initial"
alembic upgrade head

Write-Host "Seeding database..."
python scripts/seed_database.py 