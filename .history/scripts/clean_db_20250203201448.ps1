Write-Host "Cleaning database..."

# 1. 마이그레이션 롤백
Write-Host "Rolling back migrations..."
try {
    alembic downgrade base
} catch {
    Write-Host "No migrations to roll back"
}

# 2. 마이그레이션 히스토리 정리
if (Test-Path "migrations/versions") {
    Remove-Item "migrations/versions/*" -Force
    Write-Host "Cleaned migration versions"
} 