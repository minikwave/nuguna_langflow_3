# 현재 스크립트의 절대 경로 가져오기
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# 관리자 권한으로 실행 여부 확인
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    return
}

# 프로젝트 디렉토리로 이동
Set-Location $projectRoot

Write-Host "Text-to-SQL 프로젝트 초기화를 시작합니다..." -ForegroundColor Cyan

# 1. .env 파일 로드
if (-Not (Test-Path ".env")) {
    Write-Error "🚨 .env 파일이 없습니다! 프로젝트 루트 디렉토리에 .env 파일을 추가하세요."
    exit 1
}
$envContent = Get-Content -Path ".env" | Where-Object { $_ -match "^(?!#).*=" }
$envContent | ForEach-Object {
    $key, $value = $_ -split "=", 2
    Set-Content env:\$key $value
}

# 2. Docker 실행 확인
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "🚨 Docker가 설치되지 않았습니다. 설치 후 다시 실행하세요." -ForegroundColor Red
    exit 1
}

$dockerStatus = docker info --format '{{json .ServerErrors}}'
if ($dockerStatus -match "error") {
    Write-Host "🚨 Docker Desktop이 실행되지 않았습니다. 실행 후 다시 시도하세요." -ForegroundColor Red
    exit 1
}

# 3. 데이터베이스 초기화
Write-Host "🔄 데이터베이스 초기화 중..." -ForegroundColor Yellow
docker-compose up -d db
Start-Sleep -Seconds 5

# PostgreSQL 실행 확인
$retry = 0
while ($retry -lt 10) {
    if (Test-NetConnection -ComputerName "localhost" -Port $env:DB_PORT -InformationLevel Quiet) {
        Write-Host "✅ PostgreSQL이 정상적으로 실행 중입니다." -ForegroundColor Green
        break
    }
    Write-Host "🔄 PostgreSQL을 기다리는 중... ($($retry+1)/10)" -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $retry++
}
if ($retry -eq 10) {
    Write-Error "🚨 PostgreSQL이 10초 내에 실행되지 않았습니다."
    exit 1
}

# 4. Python 가상환경 설정
if (-not (Test-Path "venv/Scripts/Activate.ps1")) {
    Write-Host "🔄 Python 가상환경을 새로 생성합니다..." -ForegroundColor Yellow
    python -m venv venv
}

$venvPath = ".\venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    & $venvPath
} else {
    Write-Error "🚨 가상환경 활성화 스크립트를 찾을 수 없습니다."
    exit 1
}

pip install --upgrade pip
pip install -r requirements.txt

# Alembic 마이그레이션 실행
Write-Host "🔄 Alembic 마이그레이션 적용 중..." -ForegroundColor Yellow
alembic upgrade head

# 5. Redis 실행 확인
Write-Host "🔄 Redis 실행 중..." -ForegroundColor Yellow
docker-compose up -d redis
Start-Sleep -Seconds 3
if (-not (Test-NetConnection -ComputerName "localhost" -Port 6379 -InformationLevel Quiet)) {
    Write-Error "🚨 Redis가 실행되지 않았습니다."
    exit 1
}
Write-Host "✅ Redis가 정상적으로 실행 중입니다." -ForegroundColor Green

# 6. Langflow API 실행
Write-Host "🔄 Langflow 실행 중..." -ForegroundColor Yellow
docker-compose up -d langflow
Start-Sleep -Seconds 5
Test-ServiceConnection -ServiceName "Langflow" -Port 7860 -MaxRetries 30

# 7. Backend 및 Frontend 실행
Write-Host "🔄 Backend 실행 중..." -ForegroundColor Yellow
docker-compose up -d --build backend
Test-ServiceConnection -ServiceName "Backend" -Port 5000 -MaxRetries 30

Write-Host "🔄 Frontend 실행 중..." -ForegroundColor Yellow
docker-compose up -d frontend
Test-ServiceConnection -ServiceName "Frontend" -Port 3000 -MaxRetries 30

Write-Host "✅ 모든 서비스가 정상적으로 실행되었습니다!" -ForegroundColor Green
