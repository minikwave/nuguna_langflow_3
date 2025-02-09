# 현재 스크립트의 절대 경로 가져오기
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# 로그 파일 설정
$logFile = Join-Path $projectRoot "logs\initialize_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null

# 로그 기록 함수
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

# 포트 확인 및 정리 함수
function Clear-UsedPorts {
    param (
        [int[]]$ports = @(3000, 5000, 5433, 6379, 7860)
    )
    Write-Log "🔍 사용 중인 포트 확인 중..."
    
    foreach ($port in $ports) {
        $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
        if ($process) {
            $processName = (Get-Process -Id $process).ProcessName
            Write-Log "  ⚠️ 포트 $port 가 $processName (PID: $process)에 의해 사용 중입니다."
            try {
                Stop-Process -Id $process -Force
                Write-Log "  ✅ 포트 $port 를 사용하는 프로세스를 종료했습니다."
            } catch {
                Write-Log "  ❌ 포트 $port 를 사용하는 프로세스 종료 실패: $_"
            }
        }
    }
}

# 관리자 권한 확인
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    return
}

# 프로젝트 디렉토리로 이동
Set-Location $projectRoot

Write-Log "🔧 Text-to-SQL 프로젝트 초기화를 시작합니다..."

# Docker Desktop 완전 재시작
Write-Log "🔄 Docker Desktop 재시작 중..."
Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Write-Log "⏳ Docker Desktop 시작 대기 중 (30초)..."
Start-Sleep -Seconds 30

# 사용 중인 포트 정리
Clear-UsedPorts

# Docker 실행 상태 확인
try {
    docker version | Out-Null
} catch {
    Write-Host "❌ Docker가 아직 실행되지 않았습니다. 잠시 후 다시 시도합니다..." -ForegroundColor Red
    Start-Sleep -Seconds 30
    try {
        docker version | Out-Null
    } catch {
        Write-Error "Docker를 시작할 수 없습니다. Docker Desktop이 정상적으로 실행되어 있는지 확인해주세요."
        exit 1
    }
}

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

# 전체 초기화 프로세스
try {
    # 1. Docker 완전 초기화
    Write-Log "🔄 Docker 환경 완전 초기화 중..."
    
    # 모든 컨테이너, 볼륨, 네트워크 정리
    Write-Log "  ⌛ 컨테이너 및 볼륨 정리 중..."
    docker-compose down -v --remove-orphans 2>&1 | Tee-Object -Append -FilePath $logFile
    
    Write-Log "  ⌛ 사용하지 않는 Docker 리소스 정리 중..."
    docker system prune -af --volumes 2>&1 | Tee-Object -Append -FilePath $logFile
    
    Write-Log "  ⌛ Docker 네트워크 정리 중..."
    docker network prune -f

    # 2. 프로젝트 네트워크 재생성
    Write-Log "🔄 Docker 네트워크 생성 중..."
    docker network create text-to-sql-network

    # 3. 기본 이미지 풀
    Write-Log "🔄 기본 이미지 다운로드 중..."
    docker pull postgres:13
    docker pull redis:alpine
    docker pull logspace/langflow:latest

    # 4. 이미지 빌드
    Write-Log "🔄 프로젝트 이미지 빌드 중..."
    docker-compose build --no-cache

    # 서비스 시작 전 포트 재확인
    Clear-UsedPorts

    # 5. 서비스 순차적 시작
    Write-Log "🔄 서비스 시작 중..."
    
    # DB 시작
    docker-compose up -d db 2>&1 | Tee-Object -Append -FilePath $logFile
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
    Write-Log "🔄 서비스 상태 확인 중..."
    $services = @(
        @{Name="Database"; Port=5433},
        @{Name="Redis"; Port=6379},
        @{Name="Langflow"; Port=7860},
        @{Name="Backend"; Port=5000},
        @{Name="Frontend"; Port=3000}
    )

    foreach ($service in $services) {
        if (Test-NetConnection -ComputerName "localhost" -Port $service.Port -InformationLevel Quiet) {
            Write-Log "✅ $($service.Name) is running on port $($service.Port)"
        } else {
            Write-Log "❌ $($service.Name) is not responding on port $($service.Port)"
        }
    }

    Write-Log "`n✅ 초기화가 완료되었습니다!"
    Write-Log "📝 접속 정보:"
    Write-Log "- Frontend: http://localhost:3000"
    Write-Log "- Backend: http://localhost:5000"
    Write-Log "- Langflow: http://localhost:7860"
    Write-Log "- Database: localhost:5433"
    Write-Log "- Redis: localhost:6379"
}
catch {
    $errorMessage = "🚨 초기화 중 오류가 발생했습니다: $_"
    Write-Log $errorMessage
    Write-Log "🔄 정리 작업 실행 중..."
    docker-compose down -v --remove-orphans 2>&1 | Tee-Object -Append -FilePath $logFile
    
    Write-Log "❗ 자세한 오류 내용은 다음 로그 파일을 확인하세요:"
    Write-Log $logFile
    
    # 오류 발생 시 바로 종료하지 않고 사용자 입력 대기
    Read-Host "Enter 키를 눌러 종료하세요..."
    exit 1
}

Write-Log "`n⚠️ 스크립트 실행이 완료되었습니다. 로그 파일 위치: $logFile"
Read-Host "Enter 키를 눌러 종료하세요..."
