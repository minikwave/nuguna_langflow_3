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

# 디렉토리 구조 확인 및 생성
$directories = @(
    "logs",
    "backups",
    "frontend",
    "backend",
    "scripts\utils",
    "scripts\frontend",
    "scripts\backend",
    "scripts\services"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}

# Docker Desktop 실행 상태 확인
$dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if (-not $dockerProcess) {
    Write-Host "🔄 Docker Desktop 시작 중..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Host "⏳ Docker Desktop 시작 대기 중 (30초)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# 전체 초기화 프로세스
try {
    # 1. 모든 컨테이너, 볼륨, 네트워크 정리
    Write-Host "🔄 Docker 리소스 정리 중..." -ForegroundColor Yellow
    docker-compose down -v --remove-orphans
    docker system prune -af --volumes
    docker network prune -f

    # 2. 프로젝트 네트워크 재생성
    Write-Host "🔄 Docker 네트워크 생성 중..." -ForegroundColor Yellow
    docker network create text-to-sql-network

    # 3. 기본 이미지 풀
    Write-Host "🔄 기본 이미지 다운로드 중..." -ForegroundColor Yellow
    docker pull postgres:13
    docker pull redis:alpine
    docker pull logspace/langflow:latest

    # 4. 이미지 빌드
    Write-Host "🔄 프로젝트 이미지 빌드 중..." -ForegroundColor Yellow
    docker-compose build --no-cache

    # 5. 서비스 순차적 시작
    Write-Host "🔄 서비스 시작 중..." -ForegroundColor Yellow
    
    # DB 시작
    docker-compose up -d db
    Wait-ForHealthyContainer "text-to-sql-db" 30
    
    # Redis 시작
    docker-compose up -d redis
    Wait-ForHealthyContainer "text-to-sql-redis" 20
    
    # Langflow 시작
    docker-compose up -d langflow
    Wait-ForHealthyContainer "text-to-sql-langflow" 30
    
    # Backend 시작
    docker-compose up -d backend
    Wait-ForHealthyContainer "text-to-sql-backend" 30
    
    # Frontend 시작
    docker-compose up -d frontend
    Start-Sleep -Seconds 5

    # 6. 최종 상태 확인
    Write-Host "🔄 서비스 상태 확인 중..." -ForegroundColor Yellow
    $services = @(
        @{Name="Database"; Port=5433},
        @{Name="Redis"; Port=6379},
        @{Name="Langflow"; Port=7860},
        @{Name="Backend"; Port=5000},
        @{Name="Frontend"; Port=3000}
    )

    foreach ($service in $services) {
        if (Test-NetConnection -ComputerName "localhost" -Port $service.Port -InformationLevel Quiet) {
            Write-Host "✅ $($service.Name) is running on port $($service.Port)" -ForegroundColor Green
        } else {
            Write-Host "❌ $($service.Name) is not responding on port $($service.Port)" -ForegroundColor Red
        }
    }

    Write-Host "`n✅ 초기화가 완료되었습니다!" -ForegroundColor Green
    Write-Host "📝 접속 정보:" -ForegroundColor Cyan
    Write-Host "- Frontend: http://localhost:3000" -ForegroundColor White
    Write-Host "- Backend: http://localhost:5000" -ForegroundColor White
    Write-Host "- Langflow: http://localhost:7860" -ForegroundColor White
    Write-Host "- Database: localhost:5433" -ForegroundColor White
    Write-Host "- Redis: localhost:6379" -ForegroundColor White

}
catch {
    Write-Error "🚨 초기화 중 오류가 발생했습니다: $_"
    Write-Host "🔄 정리 작업 실행 중..." -ForegroundColor Yellow
    docker-compose down -v --remove-orphans
    exit 1
}

# PowerShell 자동 종료 방지
Write-Host "`n⚠️ 스크립트 실행이 완료되었습니다. 창을 닫으려면 Enter 키를 누르세요..."
Read-Host "Press Enter to exit"
