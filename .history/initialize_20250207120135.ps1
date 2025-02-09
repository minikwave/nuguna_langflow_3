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

# Docker 네트워크 확인 및 생성
Write-Host "🔄 Docker 네트워크 확인 중..." -ForegroundColor Yellow
docker network prune -f  # 사용하지 않는 네트워크 정리
if (-not (docker network ls --filter name=text-to-sql-network -q)) {
    Write-Host "🔄 Docker 네트워크 생성 중..." -ForegroundColor Yellow
    docker network create text-to-sql-network
}

# 서비스 시작 전 이미지 빌드
Write-Host "🔄 Docker 이미지 빌드 중..." -ForegroundColor Yellow
docker-compose build --no-cache

# 기존 컨테이너 정리
Write-Host "🔄 기존 Docker 컨테이너 정리 중..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans

# 헬스체크 함수 추가
function Wait-ForHealthyContainer {
    param (
        [string]$containerName,
        [int]$timeoutSeconds
    )
    
    $retry = 0
    while ($retry -lt $timeoutSeconds) {
        $health = docker inspect --format='{{.State.Health.Status}}' $containerName 2>$null
        if ($health -eq "healthy") {
            Write-Host "✅ $containerName 가 정상적으로 실행 중입니다." -ForegroundColor Green
            return $true
        }
        Write-Host "🔄 $containerName 상태 확인 중... ($($retry+1)/$timeoutSeconds) - Status: $health" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        $retry++
    }
    Write-Error "🚨 $containerName 가 $timeoutSeconds 초 내에 정상화되지 않았습니다."
    return $false
}

# 서비스 순차적 시작
Write-Host "🔄 서비스 시작 중..." -ForegroundColor Yellow
docker-compose up -d --no-deps db
Wait-ForHealthyContainer "text-to-sql-db" 30

docker-compose up -d --no-deps redis
Wait-ForHealthyContainer "text-to-sql-redis" 20

docker-compose up -d --no-deps langflow
Wait-ForHealthyContainer "text-to-sql-langflow" 30

docker-compose up -d --no-deps backend
Wait-ForHealthyContainer "text-to-sql-backend" 30

docker-compose up -d --no-deps frontend

Write-Host "✅ 모든 서비스가 정상적으로 실행되었습니다!" -ForegroundColor Green

# PowerShell 자동 종료 방지
Write-Host "`n⚠️ 스크립트 실행이 완료되었습니다. 창을 닫으려면 Enter 키를 누르세요..."
Read-Host "Press Enter to exit"
