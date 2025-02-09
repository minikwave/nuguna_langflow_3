# 현재 스크립트의 절대 경로 가져오기
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# 1️⃣ 관리자 권한 확인
$adminCheck = ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $adminCheck) {
    Write-Host "⚠️ 관리자 권한이 필요합니다. 관리자 권한으로 다시 실행합니다..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -Wait
    exit
}

# 2️⃣ 로그 설정
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir "initialize_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# 3️⃣ 로그 기록 함수
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

# 4️⃣ 실행 정책 확인 및 설정
Set-ExecutionPolicy Bypass -Scope Process -Force

# 5️⃣ 사용 중인 포트 종료
function Stop-UsedPorts {
    param ([int[]]$ports = @(5433, 6379, 5000, 3000, 7860))
    
    Write-Log "🔍 포트 확인 및 종료..."
    foreach ($port in $ports) {
        $processId = netstat -ano | findstr ":$port" | ForEach-Object { ($_ -split "\s+")[-1] }
        if ($processId -match "^\d+$") {
            taskkill /PID $processId /F
            Write-Log "✅ 포트 $port 종료 완료"
        }
    }
}

# 6️⃣ Docker 서비스 확인 및 재시작
function Test-DockerService {
    Write-Log "🔄 Docker 상태 확인 중..."
    try {
        docker ps | Out-Null
    } catch {
        Write-Log "⚠️ Docker가 비정상적으로 종료됨! Docker 재시작 중..."
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        Start-Sleep -Seconds 10
        if (-not (Test-DockerAvailability)) {
            throw "Docker를 정상적으로 실행할 수 없습니다."
        }
    }
}

# 7️⃣ Docker 네트워크 확인 및 생성
function New-DockerNetwork {
    Write-Log "🌐 Docker 네트워크 확인 중..."
    if (-not (docker network ls | Select-String "text-to-sql-network")) {
        docker network create --driver bridge text-to-sql-network
        Write-Log "✅ Docker 네트워크 생성 완료"
    } else {
        Write-Log "✅ 기존 네트워크가 존재합니다."
    }
}

# 8️⃣ 볼륨 확인 및 생성
function New-DockerVolume {
    Write-Log "💾 Docker 볼륨 확인 중..."
    if (-not (docker volume ls | Select-String "text-to-sql-volume")) {
        docker volume create text-to-sql-volume
        Write-Log "✅ Docker 볼륨 생성 완료"
    } else {
        Write-Log "✅ 기존 볼륨이 존재합니다."
    }
}

# 9️⃣ 기존 컨테이너 정리
function Clean-Containers {
    Write-Log "🗑 기존 컨테이너 정리 중..."
    docker ps -aq | ForEach-Object { docker stop $_; docker rm $_ }
}

# 🔟 Docker 이미지 다운로드
function Pull-DockerImages {
    Write-Log "📥 필요한 Docker 이미지 다운로드 중..."
    docker pull postgres:latest
    docker pull redis:latest
    docker pull langflow/langflow:latest
    docker pull my-backend-image
    docker pull my-frontend-image
    Write-Log "✅ Docker 이미지 다운로드 완료"
}

# 1️⃣1️⃣ 컨테이너 실행
function Start-Containers {
    Write-Log "🚀 컨테이너 실행 중..."
    docker run -d --name text-to-sql-db --network text-to-sql-network -e POSTGRES_PASSWORD=mysecurepassword -p 5433:5432 postgres:latest
    docker run -d --name text-to-sql-redis --network text-to-sql-network -p 6379:6379 redis:latest
    docker run -d --name text-to-sql-backend --network text-to-sql-network -p 5000:5000 my-backend-image
    docker run -d --name text-to-sql-frontend --network text-to-sql-network -p 3000:3000 my-frontend-image
    docker run -d --name text-to-sql-langflow --network text-to-sql-network -p 7860:7860 langflow/langflow:latest
}

# Docker 이미지 빌드 함수 추가
function Build-DockerImages {
    param (
        [string]$projectRoot
    )
    Write-Log "🏗️ Docker 이미지 빌드 시작..."

    # 백엔드 이미지 빌드
    Write-Log "  📦 백엔드 이미지 빌드 중..."
    $backendPath = Join-Path $projectRoot "backend"
    if (Test-Path $backendPath) {
        docker build -t text-to-sql-backend:latest $backendPath
        if ($LASTEXITCODE -ne 0) {
            throw "백엔드 이미지 빌드 실패"
        }
        Write-Log "    ✅ 백엔드 이미지 빌드 완료"
    }

    # 프론트엔드 이미지 빌드
    Write-Log "  📦 프론트엔드 이미지 빌드 중..."
    $frontendPath = Join-Path $projectRoot "frontend"
    if (Test-Path $frontendPath) {
        docker build -t text-to-sql-frontend:latest $frontendPath
        if ($LASTEXITCODE -ne 0) {
            throw "프론트엔드 이미지 빌드 실패"
        }
        Write-Log "    ✅ 프론트엔드 이미지 빌드 완료"
    }
}

# 랭플로우 설정 함수 추가
function Start-LangflowService {
    param (
        [string]$containerName = "text-to-sql-langflow",
        [int]$timeoutSeconds = 120
    )
    
    Write-Log "🚀 Langflow 서비스 시작 중..."
    
    # 랭플로우 전용 환경변수 설정
    $langflowEnv = @(
        "LANGFLOW_AUTO_SAVING=true",
        "LANGFLOW_SUPERUSER=admin",
        "LANGFLOW_SUPERUSER_PASSWORD=securepassword",
        "LANGFLOW_SECRET_KEY=your-secure-secret-key",
        "LANGFLOW_DATABASE_URL=sqlite:///langflow.db"
    )
    
    # 랭플로우 컨테이너 실행
    docker run -d `
        --name $containerName `
        --network text-to-sql-network `
        -p 7860:7860 `
        -e $langflowEnv `
        langflow/langflow:latest
        
    # 상태 확인
    if (-not (Test-ContainerHealth -containerName $containerName -timeoutSeconds $timeoutSeconds)) {
        throw "Langflow 서비스 시작 실패"
    }
    
    Write-Log "✅ Langflow 서비스 시작 완료"
}

# 🚀 실행 프로세스
Write-Log "🔧 Docker 기반 프로젝트 초기화 시작..."
Stop-UsedPorts
Test-DockerService
New-DockerNetwork
New-DockerVolume
Clean-Containers
Pull-DockerImages
Start-Containers
Write-Log "✅ 모든 컨테이너가 정상적으로 실행되었습니다!"

# Docker 가용성 확인 함수 수정
function Test-DockerAvailability {
    param (
        [int]$maxRetries = 60
    )
    
    Write-Log "  🔄 Docker 엔진 준비 상태 확인 중..."
    for ($i = 0; $i -lt $maxRetries; $i++) {
        try {
            $null = docker version
            Write-Log "  ✅ Docker 엔진이 준비되었습니다."
            return $true
        }
        catch {
            Write-Log "    ⏳ Docker 준비 중... ($($i+1)/$maxRetries)"
            Start-Sleep -Seconds 5
        }
    }
    return $false
}

# 컨테이너 상태 확인 함수 수정
function Test-ContainerHealth {
    param (
        [string]$containerName,
        [int]$timeoutSeconds = 60
    )
    
    Write-Log "  ⏳ $containerName 상태 확인 중..."
    $startTime = Get-Date
    
    while (((Get-Date) - $startTime).TotalSeconds -lt $timeoutSeconds) {
        try {
            $containerStatus = docker ps -a --filter "name=$containerName" --format "{{.Status}}"
            if (-not $containerStatus) {
                Write-Log "    ⚠️ 컨테이너가 존재하지 않습니다."
                return $false
            }

            $healthStatus = docker inspect -f '{{.State.Health.Status}}' $containerName 2>$null
            Write-Log "    📊 상태: $healthStatus"
            
            if ($healthStatus -eq "healthy") {
                Write-Log "    ✅ $containerName 준비 완료"
                return $true
            }
            elseif ($healthStatus -eq "unhealthy") {
                Write-Log "    ❌ $containerName 상태 불량"
                docker logs $containerName --tail 10
                return $false
            }
        }
        catch {
            Write-Log "    ⚠️ 상태 확인 중 오류: $_"
        }
        Start-Sleep -Seconds 5
    }
    
    Write-Log "    ❌ $containerName 시작 실패 (타임아웃)"
    return $false
}

# 메인 실행 부분
try {
    Write-Log "🔧 Text-to-SQL 프로젝트 초기화를 시작합니다..."
    
    # 이미지 빌드 추가
    Build-DockerImages -projectRoot $projectRoot
    
    # 서비스 시작 순서 수정
    $services = @(
        @{
            Name = "db"
            Container = "text-to-sql-db"
            Timeout = 60
            Env = @{
                POSTGRES_USER = "postgres"
                POSTGRES_PASSWORD = "postgres"
                POSTGRES_DB = "text_to_sql"
            }
        },
        @{
            Name = "redis"
            Container = "text-to-sql-redis"
            Timeout = 30
            Env = @{}
        }
    )
    
    foreach ($service in $services) {
        if (-not (Test-ContainerHealth -containerName $service.Container -timeoutSeconds $service.Timeout)) {
            throw "$($service.Name) 서비스 시작 실패"
        }
    }
    
    # 랭플로우 별도 시작
    Start-LangflowService
    
    # 백엔드 시작
    Write-Log "🚀 백엔드 서비스 시작 중..."
    docker run -d `
        --name text-to-sql-backend `
        --network text-to-sql-network `
        -p 5000:5000 `
        -e "DATABASE_URL=postgresql://postgres:postgres@db:5432/text_to_sql" `
        -e "REDIS_URL=redis://redis:6379/0" `
        -e "LANGFLOW_API_URL=http://text-to-sql-langflow:7860" `
        text-to-sql-backend:latest
    
    # 프론트엔드 시작
    Write-Log "🚀 프론트엔드 서비스 시작 중..."
    docker run -d `
        --name text-to-sql-frontend `
        --network text-to-sql-network `
        -p 3000:3000 `
        -e "REACT_APP_API_URL=http://localhost:5000" `
        -e "REACT_APP_LANGFLOW_URL=http://localhost:7860" `
        text-to-sql-frontend:latest
    
    # 최종 상태 확인
    Write-Log "`n✅ 초기화가 완료되었습니다!"
    Write-Log "📝 서비스 접속 정보:"
    Write-Log "- Frontend: http://localhost:3000"
    Write-Log "- Backend: http://localhost:5000"
    Write-Log "- Langflow: http://localhost:7860"
    Write-Log "- Database: localhost:5433"
    Write-Log "- Redis: localhost:6379"
}
catch {
    Write-Log "🚨 초기화 중 오류 발생: $_"
    Write-Log "🔄 정리 작업 실행 중..."
    docker-compose down -v --remove-orphans 2>&1 | Out-Null
    Write-Log "❗ 자세한 오류는 로그 파일을 확인하세요: $logFile"
}
finally {
    Write-Log "`n⚠️ 스크립트 실행이 완료되었습니다. 로그 파일 위치: $logFile"
    Read-Host "Enter 키를 눌러 종료하세요..."
}
