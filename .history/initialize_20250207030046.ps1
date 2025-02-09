# 현재 스크립트의 절대 경로 가져오기
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# 관리자 권한으로 새 PowerShell 프로세스 시작
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# 프로젝트 디렉토리로 이동
Set-Location $projectRoot

Write-Host "Text-to-SQL 프로젝트 초기화를 시작합니다..." -ForegroundColor Cyan

# 1. Chocolatey 설치 확인 및 설치
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey 설치 중..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# 2. 필요한 도구들 설치
Write-Host "필요한 도구 설치 중..." -ForegroundColor Yellow
choco install postgresql nodejs docker-desktop -y --no-progress

# 3. Docker Desktop 실행 확인
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerProcess) {
        Write-Host "Docker Desktop 시작 중..." -ForegroundColor Yellow
        Start-Process $dockerPath
        Start-Sleep -Seconds 30
    }
}

# 4. 데이터베이스 초기화
Write-Host "데이터베이스 초기화 중..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File .\scripts\reset_db.ps1

# 5. 프론트엔드 설정
Write-Host "프론트엔드 설정 중..." -ForegroundColor Yellow
Push-Location frontend
if (Test-Path "package.json") {
    # package.json 백업
    Copy-Item "package.json" "package.json.backup"
    
    # TypeScript 버전 다운그레이드
    npm uninstall typescript
    npm install typescript@4.9.5 --save-dev --legacy-peer-deps
    
    # 의존성 설치
    npm install --legacy-peer-deps
}
Pop-Location

# 6. Docker Compose 실행
Write-Host "Docker Compose 실행 중..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans

# 서비스 순차적 시작
Write-Host "데이터베이스 시작 중..." -ForegroundColor Yellow
docker-compose up -d db
Test-ServiceConnection -ServiceName "Database" -Port 5433 -MaxRetries 30

Write-Host "Redis 시작 중..." -ForegroundColor Yellow
docker-compose up -d redis
Test-ServiceConnection -ServiceName "Redis" -Port 6379 -MaxRetries 30

Write-Host "Langflow 시작 중..." -ForegroundColor Yellow
docker-compose up -d langflow
Test-ServiceConnection -ServiceName "Langflow" -Port 7860 -MaxRetries 60

# 백엔드 빌드 및 시작
Write-Host "Backend 빌드 및 시작 중..." -ForegroundColor Yellow

# backend 디렉토리가 없으면 생성
if (-not (Test-Path "backend")) {
    New-Item -ItemType Directory -Path "backend"
}

# requirements.txt 생성
if (-not (Test-Path "backend/requirements.txt")) {
    @"
fastapi==0.68.1
uvicorn==0.15.0
sqlalchemy==1.4.23
psycopg2-binary==2.9.1
python-dotenv==0.19.0
redis==4.0.2
requests==2.26.0
"@ | Out-File -FilePath "backend/requirements.txt" -Encoding UTF8
}

# main.py 생성
if (-not (Test-Path "backend/main.py")) {
    @"
from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)
"@ | Out-File -FilePath "backend/main.py" -Encoding UTF8
}

# Dockerfile 생성
if (-not (Test-Path "backend/Dockerfile")) {
    @"
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "main.py"]
"@ | Out-File -FilePath "backend/Dockerfile" -Encoding UTF8
}

# Python 가상환경 설정
Write-Host "Python 가상환경 설정 중..." -ForegroundColor Yellow
python -m venv venv
. .\venv\Scripts\Activate.ps1

# 필요한 패키지 설치
Write-Host "필요한 Python 패키지 설치 중..." -ForegroundColor Yellow
pip install sqlalchemy alembic psycopg2-binary

# Alembic 초기화
if (-not (Test-Path "migrations")) {
    Write-Host "Alembic 초기화 중..." -ForegroundColor Yellow
    .\venv\Scripts\alembic.exe init migrations
    
    # alembic.ini 설정
    $alembicIni = Get-Content "alembic.ini"
    $alembicIni = $alembicIni -replace "sqlalchemy.url = driver://user:pass@localhost/dbname", "sqlalchemy.url = postgresql://user:password@localhost/text_to_sql"
    $alembicIni | Set-Content "alembic.ini"
}

# 백엔드 빌드 및 시작
docker-compose up -d --build backend
Test-ServiceConnection -ServiceName "Backend" -Port 5000 -MaxRetries 30

Write-Host "Frontend 시작 중..." -ForegroundColor Yellow
docker-compose up -d frontend
Test-ServiceConnection -ServiceName "Frontend" -Port 3000 -MaxRetries 30

# 최종 상태 확인
$services = @{
    "Database" = 5433
    "Redis" = 6379
    "Langflow" = 7860
    "Backend" = 5000
    "Frontend" = 3000
}

$failedServices = @()
foreach ($service in $services.GetEnumerator()) {
    if (-not (Test-ServiceConnection -ServiceName $service.Key -Port $service.Value -MaxRetries 5)) {
        $failedServices += $service.Key
    }
}

if ($failedServices.Count -gt 0) {
    Write-Host "`n경고: 다음 서비스가 정상적으로 시작되지 않았습니다:" -ForegroundColor Red
    foreach ($service in $failedServices) {
        Write-Host "- $service" -ForegroundColor Red
    }
    Write-Host "docker-compose logs를 확인해 주세요." -ForegroundColor Yellow
    docker-compose logs
}

Write-Host "`n초기화가 완료되었습니다!" -ForegroundColor Green
Write-Host "
서비스 접속 정보:
- Frontend: http://localhost:3000
- Backend: http://localhost:5000
- Langflow: http://localhost:7860
- Database: http://localhost:5433
- Redis: http://localhost:6379
" -ForegroundColor Cyan


# 로그 파일 생성
$logMessage = @"
Initialization completed at $(Get-Date)
Docker version: $(docker --version)
Python version: $(python --version)
Node version: $(node --version)
PostgreSQL version: $(psql --version)
"@
$logMessage | Out-File -FilePath "logs/init_$(Get-Date -Format 'yyyyMMddHHmmss').log" -Encoding UTF8

# 환경 변수 설정
$env:PATH = @(
    $env:PATH
    "C:\Program Files\PostgreSQL\*\bin"
    ".\venv\Scripts"
) -join ";" 