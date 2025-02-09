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

# Docker Desktop 시작 및 대기 함수 추가
function Start-DockerDesktop {
    Write-Log "🔄 Docker Desktop 시작 확인 중..."
    
    # Docker Desktop 프로세스 확인
    $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerProcess) {
        Write-Log "  ⌛ Docker Desktop 시작 중..."
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    }
    
    # Docker 엔진 연결 대기
    $maxAttempts = 60  # 최대 2분 대기
    $attempt = 0
    $connected = $false
    
    Write-Log "  ⏳ Docker 엔진 연결 대기 중..."
    while ($attempt -lt $maxAttempts) {
        try {
            $null = docker info 2>&1
            if ($LASTEXITCODE -eq 0) {
                $connected = $true
                Write-Log "  ✅ Docker 엔진 연결 성공"
                break
            }
        }
        catch {
            Write-Log "  ⌛ Docker 엔진 연결 시도 중... ($attempt/$maxAttempts)"
        }
        
        Start-Sleep -Seconds 2
        $attempt++
    }
    
    if (-not $connected) {
        Write-Log "  ❌ Docker 엔진 연결 실패"
        throw "Docker Desktop 시작 실패"
    }
    
    # 추가 안정화 대기
    Write-Log "  ⏳ Docker 시스템 안정화 대기 중..."
    Start-Sleep -Seconds 10
}

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

# 컨테이너 헬스체크 함수 추가
function Wait-ForHealthyContainer {
    param (
        [string]$containerName,
        [int]$timeoutSeconds = 30
    )
    
    Write-Log "⏳ $containerName 상태 확인 중..."
    $elapsed = 0
    $retryInterval = 2
    
    while ($elapsed -lt $timeoutSeconds) {
        # 컨테이너 실행 상태 확인
        $status = docker inspect --format='{{.State.Status}}' $containerName 2>$null
        if ($status -ne "running") {
            Write-Log "  ⚠️ $containerName 컨테이너가 아직 실행 중이 아닙니다. 상태: $status"
            if ($containerName -eq "text-to-sql-backend") {
                Write-Log "  📝 Backend 로그 확인:"
                docker logs $containerName 2>&1 | Tee-Object -Append -FilePath $logFile
            }
            Start-Sleep -Seconds $retryInterval
            $elapsed += $retryInterval
            continue
        }

        # Backend 특별 처리
        if ($containerName -eq "text-to-sql-backend") {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -Method GET -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    Write-Log "✅ $containerName 가 정상적으로 실행되었습니다."
                    return $true
                }
            }
            catch {
                Write-Log "  ⚠️ Backend 헬스체크 응답 대기 중... ($elapsed/$timeoutSeconds)"
            }
        }
        else {
            $health = docker inspect --format='{{.State.Health.Status}}' $containerName 2>$null
            if ($health -eq "healthy") {
                Write-Log "✅ $containerName 가 정상적으로 실행되었습니다."
                return $true
            }
            Write-Log "  ⚠️ 컨테이너 상태: $health"
        }
        
        Start-Sleep -Seconds $retryInterval
        $elapsed += $retryInterval
    }
    
    Write-Log "❌ $containerName 가 정상적으로 시작되지 않았습니다."
    Write-Log "  📝 컨테이너 로그:"
    docker logs $containerName 2>&1 | Tee-Object -Append -FilePath $logFile
    return $false
}

# docker-compose.yml의 external network 문제 해결
try {
    # Docker Desktop 시작 및 대기
    Start-DockerDesktop
    
    # 전체 초기화 프로세스
    Write-Log "🔄 Docker 환경 완전 초기화 중..."
    
    # 포트 정리 전 Docker 상태 재확인
    try {
        $null = docker ps 2>&1
    }
    catch {
        Write-Log "  ⚠️ Docker 연결 재시도 중..."
        Start-DockerDesktop
    }
    
    # 포트 정리
    Clear-UsedPorts
    
    # Docker 리소스 정리
    Write-Log "  ⌛ Docker 리소스 정리 중..."
    docker-compose down -v --remove-orphans 2>&1 | Tee-Object -Append -FilePath $logFile
    docker system prune -af --volumes 2>&1 | Tee-Object -Append -FilePath $logFile
    
    # 네트워크 재설정
    Write-Log "🔄 Docker 네트워크 재설정 중..."
    docker network rm text-to-sql-network -f 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    docker network create text-to-sql-network 2>&1 | Tee-Object -Append -FilePath $logFile
    Start-Sleep -Seconds 2
    
    # 기본 이미지 풀
    Write-Log "🔄 기본 이미지 다운로드 중..."
    docker pull postgres:13 2>&1 | Tee-Object -Append -FilePath $logFile
    docker pull redis:alpine 2>&1 | Tee-Object -Append -FilePath $logFile
    
    # 서비스 순차적 시작
    Write-Log "🔄 서비스 시작 중..."
    
    # 네트워크 존재 확인
    $networkExists = docker network ls --filter name=text-to-sql-network -q
    if (-not $networkExists) {
        Write-Log "  ⚠️ 네트워크가 없어서 다시 생성합니다..."
        docker network create text-to-sql-network 2>&1 | Tee-Object -Append -FilePath $logFile
    }
    
    # DB 시작
    Write-Log "  ⌛ 데이터베이스 시작 중..."
    docker-compose up -d db 2>&1 | Tee-Object -Append -FilePath $logFile
    if (-not (Wait-ForHealthyContainer "text-to-sql-db" 30)) {
        throw "데이터베이스 시작 실패"
    }
    
    # Redis 시작
    Write-Log "  ⌛ Redis 시작 중..."
    docker-compose up -d redis 2>&1 | Tee-Object -Append -FilePath $logFile
    if (-not (Wait-ForHealthyContainer "text-to-sql-redis" 20)) {
        throw "Redis 시작 실패"
    }
    
    # Langflow 시작
    Write-Log "  ⌛ Langflow 시작 중..."
    
    # Langflow 이미지 확인 및 풀
    Write-Log "  ⌛ Langflow 이미지 확인 중..."
    
    # 여러 이미지 태그 시도
    $langflowTags = @(
        "logspace/langflow:latest",
        "logspace/langflow:0.6.3",  # 최신 안정 버전
        "logspace/langflow:main"     # 메인 브랜치 빌드
    )
    
    $imageFound = $false
    foreach ($tag in $langflowTags) {
        Write-Log "  ⌛ $tag 이미지 시도 중..."
        try {
            docker pull $tag 2>&1 | Tee-Object -Append -FilePath $logFile
            if ($LASTEXITCODE -eq 0) {
                $imageFound = $true
                # docker-compose.yml의 이미지 태그 업데이트
                (Get-Content docker-compose.yml) -replace 'image: logspace/langflow:.*', "image: $tag" | Set-Content docker-compose.yml
                Write-Log "  ✅ $tag 이미지 다운로드 성공"
                break
            }
        }
        catch {
            Write-Log "  ⚠️ $tag 이미지 다운로드 실패, 다음 태그 시도..."
            continue
        }
    }
    
    if (-not $imageFound) {
        Write-Log "  ❌ 사용 가능한 Langflow 이미지를 찾을 수 없습니다"
        throw "Langflow 이미지 다운로드 실패"
    }
    
    # Langflow 컨테이너 시작
    Write-Log "  ⌛ Langflow 컨테이너 시작 중..."
    
    # Langflow 데이터 디렉토리 생성
    if (-not (Test-Path "langflow_data")) {
        New-Item -ItemType Directory -Path "langflow_data" -Force
        Write-Log "  ✅ Langflow 데이터 디렉토리 생성됨"
    }
    
    # 기존 컨테이너 제거
    docker rm -f text-to-sql-langflow 2>$null
    
    # Langflow 컨테이너 시작
    docker-compose up -d langflow 2>&1 | Tee-Object -Append -FilePath $logFile
    
    # 컨테이너 생성 확인
    $containerExists = docker ps -a --filter "name=text-to-sql-langflow" --format "{{.Names}}"
    if (-not $containerExists) {
        Write-Log "  ❌ Langflow 컨테이너 생성 실패"
        throw "Langflow 컨테이너 생성 실패"
    }
    
    # Langflow 초기화 대기
    Write-Log "  ⏳ Langflow 초기화 대기 중..."
    Start-Sleep -Seconds 15  # 초기화 대기 시간 증가
    
    # 컨테이너 로그 확인
    Write-Log "  📝 Langflow 컨테이너 로그 확인:"
    docker logs text-to-sql-langflow 2>&1 | Tee-Object -Append -FilePath $logFile
    
    # 컨테이너 상태 확인
    if (-not (Wait-ForHealthyContainer "text-to-sql-langflow" 120)) {  # 타임아웃 증가
        Write-Log "  ⚠️ Langflow 컨테이너 로그 확인 중..."
        $containerExists = docker ps -a --filter "name=text-to-sql-langflow" --format "{{.Names}}"
        if ($containerExists) {
            docker logs text-to-sql-langflow 2>&1 | Tee-Object -Append -FilePath $logFile
        } else {
            Write-Log "  ❌ Langflow 컨테이너를 찾을 수 없습니다"
        }
        throw "Langflow 시작 실패"
    }
    
    # Backend 시작
    Write-Log "  ⌛ Backend 시작 중..."
    docker-compose up -d backend 2>&1 | Tee-Object -Append -FilePath $logFile
    if (-not (Wait-ForHealthyContainer "text-to-sql-backend" 30)) {
        throw "Backend 시작 실패"
    }
    
    # Frontend 시작
    Write-Log "  ⌛ Frontend 시작 중..."
    docker-compose up -d frontend 2>&1 | Tee-Object -Append -FilePath $logFile
    
    # 최종 상태 확인
    Write-Log "🔄 최종 상태 확인 중..."
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
