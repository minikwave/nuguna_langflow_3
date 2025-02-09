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
npm install
Pop-Location

# 6. Docker Compose 실행
Write-Host "Docker Compose 실행 중..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans
docker-compose up -d

# 서비스 연결 테스트 함수
function Test-ServiceConnection {
    param (
        [string]$ServiceName,
        [int]$Port,
        [int]$MaxRetries = 30,
        [int]$RetryInterval = 1
    )
    
    Write-Host "Waiting for $ServiceName... (Port: $Port)"
    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.ConnectAsync("localhost", $Port).Wait(1000) | Out-Null
            
            if ($tcp.Connected) {
                $tcp.Close()
                Write-Host "$ServiceName is ready! (Port: $Port)"
                return $true
            }
        }
        catch {
            Write-Host "Waiting for $ServiceName... ($($retryCount + 1)/$MaxRetries)"
            $retryCount++
            Start-Sleep -Seconds $RetryInterval
        }
    }
    Write-Host "$ServiceName failed to start!" -ForegroundColor Red
    return $false
}

# 서비스 상태 확인
Test-ServiceConnection -ServiceName "Database" -Port 5433 -MaxRetries 30

Write-Host "Redis 시작 중..." -ForegroundColor Yellow
docker-compose up -d redis
Test-ServiceConnection -ServiceName "Redis" -Port 6379 -MaxRetries 30

Write-Host "Langflow 시작 중..." -ForegroundColor Yellow
docker-compose up -d langflow
Test-ServiceConnection -ServiceName "Langflow" -Port 7860 -MaxRetries 60

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