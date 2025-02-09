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

# 5️⃣ `docker-compose.yml` 존재 여부 확인
if (-not (Test-Path "$projectRoot\docker-compose.yml")) {
    Write-Log "⚠️ docker-compose.yml이 없습니다. 수동 실행 모드로 전환합니다."
    $useCompose = $false
} else {
    $useCompose = $true
}

# 6️⃣ 기존 컨테이너 및 이미지 정리
function Reset-Docker {
    Write-Log "🔄 기존 Docker 환경 초기화 중..."
    if ($useCompose) {
        docker-compose down -v --remove-orphans 2>&1 | Tee-Object -FilePath $logFile -Append
    }
    docker system prune -af --volumes 2>&1 | Tee-Object -FilePath $logFile -Append
    Write-Log "✅ Docker 초기화 완료"
}

# 7️⃣ 사용 중인 포트 종료
function Clear-UsedPorts {
    param ([int[]]$ports = @(5433, 6379, 5000, 3000))
    Write-Log "🔍 사용 중인 포트 확인 및 종료..."
    foreach ($port in $ports) {
        $pid = netstat -ano | findstr ":$port" | ForEach-Object { ($_ -split "\s+")[-1] }
        if ($pid -match "^\d+$") {
            taskkill /PID $pid /F
            Write-Log "✅ 포트 $port 종료 완료"
        }
    }
}

# 8️⃣ 네트워크 확인 및 생성
function Ensure-DockerNetwork {
    Write-Log "🌐 Docker 네트워크 확인 중..."
    if (-not (docker network ls | Select-String "text-to-sql-network")) {
        docker network create text-to-sql-network
        Write-Log "✅ Docker 네트워크 생성 완료"
    } else {
        Write-Log "✅ 기존 네트워크가 존재합니다."
    }
}

# 9️⃣ 볼륨 확인 및 생성
function Ensure-DockerVolume {
    Write-Log "💾 Docker 볼륨 확인 중..."
    if (-not (docker volume ls | Select-String "text-to-sql-volume")) {
        docker volume create text-to-sql-volume
        Write-Log "✅ Docker 볼륨 생성 완료"
    } else {
        Write-Log "✅ 기존 볼륨이 존재합니다."
    }
}

# 🔟 필요한 Docker 이미지 다운로드
function Pull-DockerImages {
    Write-Log "📥 필요한 Docker 이미지 다운로드 중..."
    docker pull postgres:latest 2>&1 | Tee-Object -FilePath $logFile -Append
    docker pull redis:latest 2>&1 | Tee-Object -FilePath $logFile -Append
    Write-Log "✅ Docker 이미지 다운로드 완료"
}

# 1️⃣1️⃣ 컨테이너 실행 (docker-compose 또는 docker run)
function Start-Containers {
    if ($useCompose) {
        Write-Log "📦 docker-compose 기반 컨테이너 실행 중..."
        docker-compose up -d 2>&1 | Tee-Object -FilePath $logFile -Append
    } else {
        Write-Log "📦 개별 컨테이너 실행 중..."
        docker run -d --name text-to-sql-db --network text-to-sql-network `
            -e POSTGRES_PASSWORD=mysecurepassword -p 5433:5432 postgres:latest 2>&1 | Tee-Object -FilePath $logFile -Append
        docker run -d --name text-to-sql-redis --network text-to-sql-network -p 6379:6379 redis:latest 2>&1 | Tee-Object -FilePath $logFile -Append
    }
}

# 1️⃣2️⃣ 컨테이너 헬스체크
function Check-Container-Health {
    param([string]$containerName)
    Write-Log "🔄 $containerName 상태 확인 중..."
    for ($i=0; $i -lt 10; $i++) {
        $status = docker inspect -f '{{.State.Status}}' $containerName 2>$null
        if ($status -eq "running") {
            Write-Log "✅ $containerName 실행 완료"
            return
        }
        Start-Sleep -Seconds 5
    }
    Write-Log "❌ $containerName 실행 실패"
    exit 1
}

# 🚀 실행 프로세스
Write-Log "🔧 Docker 기반 프로젝트 초기화 시작..."
Reset-Docker
Clear-UsedPorts
Ensure-DockerNetwork
Ensure-DockerVolume
Pull-DockerImages
Start-Containers
Check-Container-Health -containerName "text-to-sql-db"
Check-Container-Health -containerName "text-to-sql-redis"
Write-Log "✅ 모든 컨테이너가 정상적으로 실행되었습니다!"



# # 현재 스크립트의 절대 경로 가져오기
# $scriptPath = $MyInvocation.MyCommand.Path
# $projectRoot = Split-Path -Parent $scriptPath

# # 관리자 권한 확인 (기존 로직 개선)
# $adminCheck = ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
# if (-not $adminCheck) {
#     Write-Host "관리자 권한으로 다시 시작합니다..."
#     Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
#     exit
# }

# # 실행 정책 설정
# Set-ExecutionPolicy Bypass -Scope Process -Force

# # 로그 디렉토리 생성 (기존 코드 개선)
# $logDir = Join-Path $projectRoot "logs"
# if (-not (Test-Path $logDir)) {
#     New-Item -ItemType Directory -Path $logDir -Force | Out-Null
# }

# # 로그 파일 설정
# $logFile = Join-Path $logDir "initialize_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# # 로그 기록 함수
# function Write-Log {
#     param($Message)
#     $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
#     Write-Host $logMessage
#     Add-Content -Path $logFile -Value $logMessage
# }

# # Docker 서비스 확인 (추가)
# function Check-DockerService {
#     $dockerService = Get-Service -Name "Docker" -ErrorAction SilentlyContinue
#     if ($dockerService -and $dockerService.Status -ne "Running") {
#         Write-Log "🔄 Docker 서비스 시작 중..."
#         Start-Service -Name "Docker"
#         Start-Sleep -Seconds 10
#     }
# }

# # 포트 확인 및 프로세스 종료 개선
# function Clear-UsedPorts {
#     param ([int[]]$ports = @(3000, 5000, 5433, 6379, 7860))

#     Write-Log "🔍 사용 중인 포트 확인 중..."
#     foreach ($port in $ports) {
#         $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | 
#                    Where-Object { $_.OwningProcess -gt 0 } | # 시스템 프로세스 제외
#                    Select-Object -ExpandProperty OwningProcess -Unique
#         if ($process) {
#             try {
#                 Stop-Process -Id $process -Force
#                 Write-Log "  ✅ 포트 $port 를 사용하는 프로세스를 종료했습니다."
#             } catch {
#                 Write-Log "  ❌ 포트 $port 종료 실패: $_"
#             }
#         }
#     }
# }

# # Docker 상태 확인 및 초기화
# function Wait-ForDocker {
#     Check-DockerService
#     Write-Log "🔄 Docker 상태 확인 중..."
    
#     # Docker Desktop 프로세스 확인
#     $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
#     if (-not $dockerProcess) {
#         Write-Log "  🚀 Docker Desktop 시작 중..."
#         Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
#     }

#     # Docker 엔진 준비 대기
#     $maxRetries = 60  # 5분 타임아웃
#     for ($i=0; $i -lt $maxRetries; $i++) {
#         try {
#             $null = docker version
#             Write-Log "  ✅ Docker 엔진이 준비되었습니다."
#             return $true
#         } catch {
#             Write-Log "  🔄 Docker 준비 중... ($($i+1)/$maxRetries)"
#             Start-Sleep -Seconds 5
#         }
#     }
    
#     throw "Docker가 준비 시간을 초과했습니다."
# }

# # Docker 컨테이너 상태 확인 함수
# function Wait-ForHealthyContainer {
#     param (
#         [string]$containerName,
#         [int]$timeoutSeconds = 30
#     )
    
#     Write-Log "  ⏳ $containerName 상태 확인 중..."
#     $startTime = Get-Date
#     $healthy = $false
    
#     # 컨테이너가 생성되었는지 먼저 확인
#     $retryCount = 0
#     while ($retryCount -lt 10) {
#         $container = docker ps -a --filter "name=$containerName" --format "{{.Names}}"
#         if ($container) {
#             break
#         }
#         Write-Log "    ⌛ 컨테이너 생성 대기 중..."
#         Start-Sleep -Seconds 2
#         $retryCount++
#     }
    
#     # 컨테이너 로그 확인
#     Write-Log "    📝 컨테이너 로그:"
#     docker logs $containerName 2>&1 | Select-Object -Last 5 | ForEach-Object {
#         Write-Log "      $_"
#     }
    
#     while (-not $healthy -and ((Get-Date) - $startTime).TotalSeconds -lt $timeoutSeconds) {
#         try {
#             $status = docker inspect -f '{{.State.Health.Status}}' $containerName 2>$null
#             Write-Log "    📊 컨테이너 상태: $status"
            
#             if ($status -eq "healthy") {
#                 $healthy = $true
#                 Write-Log "    ✅ $containerName 준비 완료"
#                 break
#             }
#             elseif ($status -eq "unhealthy") {
#                 Write-Log "    ❌ $containerName 상태 불량"
#                 docker logs $containerName 2>&1 | Select-Object -Last 10 | ForEach-Object {
#                     Write-Log "      $_"
#                 }
#                 break
#             }
#         }
#         catch {
#             Write-Log "    ⚠️ 상태 확인 중: $_"
#         }
#         Start-Sleep -Seconds 5
#     }
    
#     if (-not $healthy) {
#         Write-Log "    ❌ $containerName 시작 실패 (타임아웃: ${timeoutSeconds}초)"
#         Write-Log "    📝 마지막 로그:"
#         docker logs $containerName 2>&1 | Select-Object -Last 20 | ForEach-Object {
#             Write-Log "      $_"
#         }
#         return $false
#     }
    
#     return $true
# }

# # 서비스 시작 함수 추가
# function Start-Service {
#     param (
#         [string]$serviceName,
#         [string]$containerName,
#         [int]$timeout
#     )
    
#     Write-Log "  ⌛ $serviceName 시작 중..."
#     docker-compose up -d $serviceName 2>&1 | Out-Null
    
#     if (-not (Wait-ForHealthyContainer -containerName $containerName -timeoutSeconds $timeout)) {
#         throw "$serviceName 시작 실패"
#     }
    
#     Write-Log "  ✅ $serviceName 시작 완료"
# }

# try {
#     Write-Log "🔧 Text-to-SQL 프로젝트 초기화를 시작합니다..."
    
#     # 실행 정책 상태 확인
#     Write-Log "  📋 현재 실행 정책: $(Get-ExecutionPolicy)"
    
#     # 포트 정리
#     Clear-UsedPorts
    
#     # Docker 상태 확인 및 준비
#     if (-not (Wait-ForDocker)) {
#         throw "Docker 초기화 실패"
#     }
    
#     # Docker 네트워크 생성
#     Write-Log "  🌐 Docker 네트워크 초기화 중..."
#     docker network create text-to-sql-network 2>&1 | Out-Null
    
#     # Docker 환경 초기화 부분 수정
#     Write-Log "🔄 Docker 환경 초기화 중..."
#     docker-compose down -v --remove-orphans 2>&1 | Out-Null
#     docker system prune -af --volumes 2>&1 | Out-Null

#     # 볼륨 정리
#     Write-Log "  🧹 Docker 볼륨 정리 중..."
#     docker volume rm text-to-sql-postgres-data -f 2>&1 | Out-Null
#     docker volume create text-to-sql-postgres-data 2>&1 | Out-Null

#     Start-Sleep -Seconds 5
    
#     # 서비스 순차적 시작
#     Start-Service -serviceName "db" -containerName "text-to-sql-db" -timeout 60
#     Start-Service -serviceName "redis" -containerName "text-to-sql-redis" -timeout 30
#     Start-Service -serviceName "langflow" -containerName "text-to-sql-langflow" -timeout 120
#     Start-Service -serviceName "backend" -containerName "text-to-sql-backend" -timeout 60
    
#     # Frontend 시작 (healthcheck 없음)
#     Write-Log "  ⌛ Frontend 시작 중..."
#     docker-compose up -d frontend 2>&1 | Out-Null
#     Start-Sleep -Seconds 10
    
#     # 최종 상태 확인
#     Write-Log "🔄 최종 상태 확인 중..."
#     $services = @(
#         @{Name="Database"; Port=5433},
#         @{Name="Redis"; Port=6379},
#         @{Name="Langflow"; Port=7860},
#         @{Name="Backend"; Port=5000},
#         @{Name="Frontend"; Port=3000}
#     )
    
#     foreach ($service in $services) {
#         if (Test-NetConnection -ComputerName "localhost" -Port $service.Port -InformationLevel Quiet) {
#             Write-Log "✅ $($service.Name) is running on port $($service.Port)"
#         } else {
#             Write-Log "❌ $($service.Name) is not responding on port $($service.Port)"
#         }
#     }
    
#     Write-Log "`n✅ 초기화가 완료되었습니다!"
#     Write-Log "📝 접속 정보:"
#     Write-Log "- Frontend: http://localhost:3000"
#     Write-Log "- Backend: http://localhost:5000"
#     Write-Log "- Langflow: http://localhost:7860"
#     Write-Log "- Database: localhost:5433"
#     Write-Log "- Redis: localhost:6379"
# }
# catch {
#     Write-Log "🚨 초기화 중 오류 발생: $_"
#     Write-Log "🔄 정리 작업 실행 중..."
#     docker-compose down -v --remove-orphans 2>&1 | Out-Null
#     Write-Log "❗ 자세한 오류는 로그 파일을 확인하세요: $logFile"
#     Read-Host "Enter 키를 눌러 종료하세요..."
#     exit 1
# }

# Write-Log "`n⚠️ 스크립트 실행이 완료되었습니다. 로그 파일 위치: $logFile"
# Read-Host "Enter 키를 눌러 종료하세요..."
