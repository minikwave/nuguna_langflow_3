# 현재 스크립트의 절대 경로 가져오기
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# 관리자 권한 확인
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    return
}

# 프로젝트 디렉토리로 이동
Set-Location $projectRoot

Write-Host "🔧 Text-to-SQL 프로젝트 초기화를 시작합니다..." -ForegroundColor Cyan

# .env 파일 로드
if (-Not (Test-Path ".env")) {
    Write-Error "🚨 .env 파일이 없습니다! 프로젝트 루트 디렉토리에 .env 파일을 추가하세요."
    exit 1
}
$envContent = Get-Content -Path ".env" | Where-Object { $_ -match "^(?!#).*=" }
$envContent | ForEach-Object {
    $key, $value = $_ -split "=", 2
    Set-Content env:\$key $value
}

# PostgreSQL, Redis, Langflow, Backend, Frontend의 예상 포트 목록
$env:DB_PORT = "5433"  # 5432가 아닌 5433으로 수정
$portsToCheck = @($env:DB_PORT, 6379, 7860, 5000, 3000)

# 방화벽 규칙 추가 (모든 포트 오픈)
foreach ($port in $portsToCheck) {
    Write-Host "🔄 방화벽 규칙 추가: 포트 $port" -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "Allow Port $port" -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow -ErrorAction SilentlyContinue
}

# 기존 포트 사용 중인 프로세스 종료
foreach ($port in $portsToCheck) {
    if (Test-NetConnection -ComputerName "localhost" -Port $port -InformationLevel Quiet) {
        Write-Host "🚨 포트 $port 에서 실행 중인 프로세스를 종료합니다..." -ForegroundColor Yellow
        Stop-Process -Id (Get-NetTCPConnection -LocalPort $port).OwningProcess -Force -ErrorAction SilentlyContinue
    }
}

# PostgreSQL 개발 도구 설치 확인 및 보완
if (-not (Get-Command pg_config -ErrorAction SilentlyContinue)) {
    Write-Host "🔄 PostgreSQL 개발 도구 설치 중..." -ForegroundColor Yellow
    choco install postgresql --force -y
    $env:Path += ";C:\Program Files\PostgreSQL\17\bin"
}

# Docker 실행 확인
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "🚨 Docker가 설치되지 않았습니다. 설치 후 다시 실행하세요." -ForegroundColor Red
    exit 1
}

$dockerStatus = docker info --format '{{json .ServerErrors}}'
if ($dockerStatus -match "error") {
    Write-Host "🚨 Docker Desktop이 실행되지 않았습니다. 실행 후 다시 시도하세요." -ForegroundColor Red
    exit 1
}

# 모든 컨테이너 종료 후 다시 시작
Write-Host "🔄 기존 Docker 컨테이너 정리 중..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans

# PostgreSQL 실행 확인 및 재시작
Write-Host "🔄 데이터베이스 초기화 중..." -ForegroundColor Yellow
docker-compose up -d db
Start-Sleep -Seconds 5

$retry = 0
while ($retry -lt 10) {
    if (Test-NetConnection -ComputerName "localhost" -Port 5433 -InformationLevel Quiet) {  # 5433으로 수정
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

# Python 가상환경 설정
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
pip install --no-cache-dir psycopg2-binary
pip install -r requirements.txt

# Alembic 마이그레이션 실행
Write-Host "🔄 Alembic 마이그레이션 적용 중..." -ForegroundColor Yellow
alembic upgrade head

# Redis 실행 확인
Write-Host "🔄 Redis 실행 중..." -ForegroundColor Yellow
docker-compose up -d redis
Start-Sleep -Seconds 3
if (-not (Test-NetConnection -ComputerName "localhost" -Port 6379 -InformationLevel Quiet)) {
    Write-Error "🚨 Redis가 실행되지 않았습니다."
    exit 1
}
Write-Host "✅ Redis가 정상적으로 실행 중입니다." -ForegroundColor Green

# Langflow 실행 (Python 3.9 환경에서 실행)
Write-Host "🔄 Langflow 실행 중..." -ForegroundColor Yellow
docker-compose up -d langflow
Start-Sleep -Seconds 5

$retry = 0
while ($retry -lt 10) {
    if (Test-NetConnection -ComputerName "localhost" -Port 7860 -InformationLevel Quiet) {
        Write-Host "✅ Langflow가 정상적으로 실행 중입니다." -ForegroundColor Green
        break
    }
    Write-Host "🔄 Langflow를 기다리는 중... ($($retry+1)/10)" -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $retry++
}
if ($retry -eq 10) {
    Write-Error "🚨 Langflow가 10초 내에 실행되지 않았습니다."
    exit 1
}

# Backend 및 Frontend 실행
Write-Host "🔄 Backend 실행 중..." -ForegroundColor Yellow
docker-compose up -d --build backend
Start-Sleep -Seconds 3
if (-not (Test-NetConnection -ComputerName "localhost" -Port 5000 -InformationLevel Quiet)) {
    Write-Error "🚨 Backend가 실행되지 않았습니다."
    exit 1
}
Write-Host "✅ Backend가 정상적으로 실행 중입니다." -ForegroundColor Green

Write-Host "🔄 Frontend 실행 중..." -ForegroundColor Yellow
docker-compose up -d frontend
Start-Sleep -Seconds 3
if (-not (Test-NetConnection -ComputerName "localhost" -Port 3000 -InformationLevel Quiet)) {
    Write-Error "🚨 Frontend가 실행되지 않았습니다."
    exit 1
}
Write-Host "✅ Frontend가 정상적으로 실행 중입니다." -ForegroundColor Green

Write-Host "✅ 모든 서비스가 정상적으로 실행되었습니다!" -ForegroundColor Green

# PowerShell 자동 종료 방지
Write-Host "`n⚠️ 스크립트 실행이 완료되었습니다. 창을 닫으려면 Enter 키를 누르세요..."
Read-Host "Press Enter to exit"
