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

# 1. Chocolatey 설치 확인 및 설치
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey 설치 중..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    $chocoInstaller = "$env:TEMP\choco_install.ps1"
    Invoke-WebRequest -Uri "https://chocolatey.org/install.ps1" -OutFile $chocoInstaller
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$chocoInstaller`"" -Verb RunAs -Wait
}

# 2. 필요한 도구 설치
Write-Host "필요한 도구 설치 중..." -ForegroundColor Yellow
choco install postgresql nodejs docker-desktop -y --no-progress

# 3. Docker 실행 확인
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker가 설치되지 않았습니다. 설치 후 다시 실행하세요." -ForegroundColor Red
    exit 1
}

$dockerStatus = docker info --format '{{json .ServerErrors}}'
if ($dockerStatus -match "error") {
    Write-Host "Docker Desktop이 실행되지 않았습니다. 실행 후 다시 시도하세요." -ForegroundColor Red
    exit 1
}

# 4. 데이터베이스 초기화
Write-Host "데이터베이스 초기화 중..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File .\scripts\reset_db.ps1

# 5. 프론트엔드 설정
Write-Host "프론트엔드 설정 중..." -ForegroundColor Yellow
Push-Location frontend
if (Test-Path "package.json") {
    Copy-Item "package.json" "package.json.backup"

    Remove-Item -Recurse -Force node_modules
    npm ci --legacy-peer-deps
}
Pop-Location

# 6. Docker Compose 실행
Write-Host "Docker Compose 실행 중..." -ForegroundColor Yellow
if (docker ps -q | Select-String "db") {
    docker-compose down -v --remove-orphans
}

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

if (-not (Test-Path "venv/Scripts/Activate.ps1")) {
    Write-Host "Python 가상환경을 새로 생성합니다..." -ForegroundColor Yellow
    python -m venv venv
}

$venvPath = ".\venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    & $venvPath
} else {
    Write-Error "가상환경 활성화 스크립트를 찾을 수 없습니다."
    exit 1
}

pip install -r backend/requirements.txt

# Alembic 초기화
if (-not (Test-Path "migrations")) {
    Write-Host "Alembic 초기화 중..." -ForegroundColor Yellow
    .\venv\Scripts\alembic.exe init migrations

    $alembicIni = Get-Content "alembic.ini"
    $alembicIni = $alembicIni -replace "sqlalchemy.url = driver://user:pass@localhost/dbname", "sqlalchemy.url = postgresql://user:password@localhost/text_to_sql"
    $alembicIni | Set-Content "alembic.ini"
}

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

# 서비스 연결 테스트 함수
function Test-ServiceConnection {
    param(
        [string]$ServiceName,
        [int]$Port,
        [int]$MaxRetries = 30
    )

    for ($retryCount = 0; $retryCount -lt $MaxRetries; $retryCount++) {
        if (Test-NetConnection -ComputerName "localhost" -Port $Port -InformationLevel Quiet) {
            Write-Host "$ServiceName is ready!" -ForegroundColor Green
            return $true
        }
        Write-Host "Waiting for $ServiceName... (Attempt $retryCount of $MaxRetries)" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
    Write-Error "$ServiceName did not become available in time"
    return $false
}
