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

# 10. 서비스 시작
Write-Host "서비스 시작 중..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans
docker-compose up -d

# 11. 서비스 상태 확인
function Test-ServiceConnection {
    param (
        [string]$ServiceName,
        [int]$Port,
        [int]$MaxRetries = 30
    )
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect("localhost", $Port)
            $tcp.Close()
            Write-Host "$ServiceName is ready! (Port: $Port)" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "Waiting for $ServiceName... ($i/$MaxRetries)" -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
    Write-Host "$ServiceName failed to start!" -ForegroundColor Red
    return $false
}

$services = @{
    "Database" = 5433
    "Redis" = 6379
    "Langflow" = 7860
    "Backend" = 5000
    "Frontend" = 3000
}

foreach ($service in $services.GetEnumerator()) {
    Test-ServiceConnection -ServiceName $service.Key -Port $service.Value
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