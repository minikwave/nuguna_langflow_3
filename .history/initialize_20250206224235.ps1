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

# PowerShell 프로필에 환경 변수 추가
$profileContent = @"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
refreshenv
"@
if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -Type File -Force
}
Add-Content -Path $PROFILE -Value $profileContent

# 2. 필요한 도구들 설치
Write-Host "필요한 도구 설치 중..." -ForegroundColor Yellow
$tools = @(
    # "python",
    "postgresql",
    "nodejs",
    "docker-desktop",
    # "git",
    # "visualstudio2019buildtools",
    # "visualstudio2019-workload-vctools"
)

foreach ($tool in $tools) {
    Write-Host "Installing $tool..." -ForegroundColor Yellow
    choco install $tool -y --no-progress
}

# 환경 변수 새로고침
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# 3. Docker Desktop 실행 확인 및 시작
$dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if (-not $dockerProcess) {
    Write-Host "Docker Desktop 시작 중..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Host "Docker Desktop 시작 대기 중 (30초)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# # 4. 프로젝트 디렉토리 구조 생성
# $directories = @(
#     "src/models",
#     "src/services",
#     "src/utils",
#     "frontend",
#     "backend",
#     "logs",
#     "migrations",
#     "scripts/utils",
#     "scripts/frontend",
#     "scripts/backend",
#     "scripts/services"
# )

# foreach ($dir in $directories) {
#     if (-not (Test-Path $dir)) {
#         New-Item -ItemType Directory -Path $dir -Force
#         Write-Host "Created directory: $dir" -ForegroundColor Green
#     }
# }

# # 5. 환경 변수 파일 백업 및 생성
# if (Test-Path ".env") {
#     Copy-Item ".env" ".env.backup_$(Get-Date -Format 'yyyyMMddHHmmss')"
# }

# @"
# DB_USER=user
# DB_PASSWORD=password
# DB_NAME=text_to_sql
# DB_PORT=5433
# FLASK_APP=src.app:create_app
# FLASK_ENV=development
# REDIS_URL=redis://localhost:6379/0
# LANGFLOW_API_URL=http://localhost:7860
# "@ | Out-File -FilePath ".env" -Encoding UTF8

# 6. Python 패키지 설치
Write-Host "Python 패키지 설치 중..." -ForegroundColor Yellow
python -m pip install --upgrade pip
pip install flask flask-cors sqlalchemy alembic psycopg2-binary python-dotenv redis langflow gunicorn requests

# 7. Docker 환경 초기화
Write-Host "Docker 환경 초기화 중..." -ForegroundColor Yellow
if (Test-Path "docker-compose.yml") {
    Copy-Item "docker-compose.yml" "docker-compose.yml.backup_$(Get-Date -Format 'yyyyMMddHHmmss')"
}
powershell -ExecutionPolicy Bypass -File .\scripts\docker\setup.ps1

# 8. 데이터베이스 초기화
Write-Host "데이터베이스 초기화 중..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File .\scripts\reset_db.ps1

# 9. 프론트엔드 설정
Write-Host "프론트엔드 설정 중..." -ForegroundColor Yellow
if (Test-Path "frontend/package.json") {
    Copy-Item "frontend/package.json" "frontend/package.json.backup_$(Get-Date -Format 'yyyyMMddHHmmss')"
}
Push-Location frontend
npm install
Pop-Location

# Langflow 초기화 및 상태 확인 함수 추가
function Initialize-Langflow {
    Write-Host "Langflow 초기화 중..." -ForegroundColor Yellow
    
    # Langflow 이미지 확인 및 풀
    $langflowImage = docker images logspace/langflow:latest --quiet
    if (-not $langflowImage) {
        Write-Host "Langflow 이미지 다운로드 중..." -ForegroundColor Yellow
        docker pull logspace/langflow:latest
    }
    
    # Langflow 컨테이너 재시작
    docker-compose restart langflow
    
    # Langflow 헬스체크
    $maxRetries = 60  # Langflow는 시작이 더 오래 걸릴 수 있으므로 타임아웃 증가
    $retryCount = 0
    while ($retryCount -lt $maxRetries) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:7860/health" -Method GET -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "Langflow is ready!" -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Host "Waiting for Langflow... ($retryCount/$maxRetries)" -ForegroundColor Yellow
            $retryCount++
            Start-Sleep -Seconds 2
        }
    }
    Write-Host "Langflow failed to start!" -ForegroundColor Red
    return $false
}

# Test-ServiceConnection 함수 수정
function Test-ServiceConnection {
    param (
        [string]$ServiceName,
        [int]$Port,
        [int]$MaxRetries = 30,
        [int]$RetryInterval = 1
    )
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            if ($ServiceName -eq "Langflow") {
                $response = Invoke-WebRequest -Uri "http://localhost:$Port/health" -Method GET -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    Write-Host "$ServiceName is ready! (Port: $Port)" -ForegroundColor Green
                    return $true
                }
            } else {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $tcp.Connect("localhost", $Port)
                $tcp.Close()
                Write-Host "$ServiceName is ready! (Port: $Port)" -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Host "Waiting for $ServiceName... ($i/$MaxRetries)" -ForegroundColor Yellow
            Start-Sleep -Seconds $RetryInterval
        }
    }
    
    Write-Host "$ServiceName failed to start!" -ForegroundColor Red
    return $false
}

# 서비스 시작 부분 수정 (기존 코드의 해당 부분을 교체)
# 10. 서비스 시작
Write-Host "서비스 시작 중..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans

# 순차적으로 서비스 시작
Write-Host "데이터베이스 시작 중..." -ForegroundColor Yellow
docker-compose up -d db
Test-ServiceConnection -ServiceName "Database" -Port 5433 -MaxRetries 30

Write-Host "Redis 시작 중..." -ForegroundColor Yellow
docker-compose up -d redis
Test-ServiceConnection -ServiceName "Redis" -Port 6379 -MaxRetries 30

Write-Host "Langflow 시작 중..." -ForegroundColor Yellow
docker-compose up -d langflow
Initialize-Langflow

Write-Host "Backend 시작 중..." -ForegroundColor Yellow
docker-compose up -d backend
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
- Database: localhost:5433
- Redis: localhost:6379
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