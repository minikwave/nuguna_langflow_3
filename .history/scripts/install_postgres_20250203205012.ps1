# PostgreSQL 설치 스크립트
Write-Host "Installing PostgreSQL..."

# Chocolatey 설치 확인 및 설치
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    refreshenv
}

# PostgreSQL 설치 (포트 5434 지정)
Write-Host "Installing PostgreSQL using Chocolatey..."
choco install postgresql13 --params '/Password:password /Port:5434' -y
refreshenv

# PostgreSQL 서비스 시작
Write-Host "Starting PostgreSQL service..."
Start-Service postgresql-x64-13

# 환경 변수 설정
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

# DB 및 사용자 생성 (포트 5434 사용)
Write-Host "Creating database and user..."
$env:PGPASSWORD = "password"
$env:PGPORT = "5434"
psql -U postgres -p 5434 -c "CREATE DATABASE text_to_sql;"
psql -U postgres -p 5434 -c "CREATE USER user WITH PASSWORD 'password';"
psql -U postgres -p 5434 -c "GRANT ALL PRIVILEGES ON DATABASE text_to_sql TO user;" 