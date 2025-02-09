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

# Docker 네트워크 확인 및 생성 (기존 Docker 실행 확인 코드 아래에 추가)
Write-Host "🔄 Docker 네트워크 확인 중..." -ForegroundColor Yellow
if (-not (docker network ls --filter name=text-to-sql-network -q)) {
    Write-Host "🔄 Docker 네트워크 생성 중..." -ForegroundColor Yellow
    docker network create text-to-sql-network
}

# 모든 컨테이너 종료 후 다시 시작
Write-Host "🔄 기존 Docker 컨테이너 정리 중..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans

# PostgreSQL 실행 및 healthcheck
Write-Host "🔄 데이터베이스 초기화 중..." -ForegroundColor Yellow
docker-compose up -d db
$retry = 0
while ($retry -lt 10) {
    $health = docker inspect --format='{{.State.Health.Status}}' text-to-sql-db 2>$null
    if ($health -eq "healthy") {
        Write-Host "✅ PostgreSQL이 정상적으로 실행 중입니다." -ForegroundColor Green
        break
    }
    Write-Host "🔄 PostgreSQL 상태 확인 중... ($($retry+1)/10) - Status: $health" -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    $retry++
}
if ($retry -eq 10) {
    Write-Error "🚨 PostgreSQL이 30초 내에 정상화되지 않았습니다."
    exit 1
}

# Redis 실행 및 healthcheck
Write-Host "🔄 Redis 실행 중..." -ForegroundColor Yellow
docker-compose up -d redis
$retry = 0
while ($retry -lt 10) {
    $health = docker inspect --format='{{.State.Health.Status}}' text-to-sql-redis 2>$null
    if ($health -eq "healthy") {
        Write-Host "✅ Redis가 정상적으로 실행 중입니다." -ForegroundColor Green
        break
    }
    Write-Host "🔄 Redis 상태 확인 중... ($($retry+1)/10) - Status: $health" -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $retry++
}
if ($retry -eq 10) {
    Write-Error "🚨 Redis가 20초 내에 정상화되지 않았습니다."
    exit 1
}

# Langflow 실행 및 healthcheck
Write-Host "🔄 Langflow 실행 중..." -ForegroundColor Yellow
docker-compose up -d langflow
$retry = 0
while ($retry -lt 10) {
    $health = docker inspect --format='{{.State.Health.Status}}' text-to-sql-langflow 2>$null
    if ($health -eq "healthy") {
        Write-Host "✅ Langflow가 정상적으로 실행 중입니다." -ForegroundColor Green
        break
    }
    Write-Host "🔄 Langflow 상태 확인 중... ($($retry+1)/10) - Status: $health" -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    $retry++
}
if ($retry -eq 10) {
    Write-Error "🚨 Langflow가 30초 내에 정상화되지 않았습니다."
    exit 1
}

# Backend 실행 및 healthcheck
Write-Host "🔄 Backend 실행 중..." -ForegroundColor Yellow
docker-compose up -d --build backend
$retry = 0
while ($retry -lt 10) {
    $health = docker inspect --format='{{.State.Health.Status}}' text-to-sql-backend 2>$null
    if ($health -eq "healthy") {
        Write-Host "✅ Backend가 정상적으로 실행 중입니다." -ForegroundColor Green
        break
    }
    Write-Host "🔄 Backend 상태 확인 중... ($($retry+1)/10) - Status: $health" -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    $retry++
}
if ($retry -eq 10) {
    Write-Error "🚨 Backend가 30초 내에 정상화되지 않았습니다."
    exit 1
}

# Frontend 실행
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
