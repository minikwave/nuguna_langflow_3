# 현재 스크립트의 절대 경로 가져오기
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# 관리자 권한 확인 (기존 로직 개선)
$adminCheck = ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $adminCheck) {
    Write-Host "관리자 권한으로 다시 시작합니다..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# 실행 정책 설정
Set-ExecutionPolicy Bypass -Scope Process -Force

# 로그 디렉토리 생성 (기존 코드 개선)
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# 로그 파일 설정
$logFile = Join-Path $logDir "initialize_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# 로그 기록 함수
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

# Docker 서비스 확인 (추가)
function Check-DockerService {
    $dockerService = Get-Service -Name "Docker" -ErrorAction SilentlyContinue
    if ($dockerService -and $dockerService.Status -ne "Running") {
        Write-Log "🔄 Docker 서비스 시작 중..."
        Start-Service -Name "Docker"
        Start-Sleep -Seconds 10
    }
}

# 포트 확인 및 프로세스 종료 개선
function Clear-UsedPorts {
    param ([int[]]$ports = @(3000, 5000, 5433, 6379, 7860))

    Write-Log "🔍 사용 중인 포트 확인 중..."
    foreach ($port in $ports) {
        $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | 
                   Where-Object { $_.OwningProcess -gt 0 } | # 시스템 프로세스 제외
                   Select-Object -ExpandProperty OwningProcess -Unique
        if ($process) {
            try {
                Stop-Process -Id $process -Force
                Write-Log "  ✅ 포트 $port 를 사용하는 프로세스를 종료했습니다."
            } catch {
                Write-Log "  ❌ 포트 $port 종료 실패: $_"
            }
        }
    }
}

# Docker 상태 확인 및 초기화
function Wait-ForDocker {
    Check-DockerService
    Write-Log "🔄 Docker 상태 확인 중..."
    
    # Docker Desktop 프로세스 확인
    $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerProcess) {
        Write-Log "  🚀 Docker Desktop 시작 중..."
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    }

    # Docker 엔진 준비 대기
    $maxRetries = 60  # 5분 타임아웃
    for ($i=0; $i -lt $maxRetries; $i++) {
        try {
            $null = docker version
            Write-Log "  ✅ Docker 엔진이 준비되었습니다."
            return $true
        } catch {
            Write-Log "  🔄 Docker 준비 중... ($($i+1)/$maxRetries)"
            Start-Sleep -Seconds 5
        }
    }
    
    throw "Docker가 준비 시간을 초과했습니다."
}

try {
    Write-Log "🔧 Text-to-SQL 프로젝트 초기화를 시작합니다..."

    # 실행 정책 상태 확인
    Write-Log "  📋 현재 실행 정책: $(Get-ExecutionPolicy)"
    
    # 포트 정리
    Clear-UsedPorts

    # Docker 상태 확인 및 준비
    if (-not (Wait-ForDocker)) {
        throw "Docker 초기화 실패"
    }

    # 기존 리소스 정리
    Write-Log "🔄 Docker 환경 초기화 중..."
    docker-compose down -v --remove-orphans 2>&1 | Out-Null
    docker system prune -af --volumes 2>&1 | Out-Null
    Start-Sleep -Seconds 5

    # 서비스 순차적 시작 (컨테이너 완료 후 다음 실행)
    Write-Log "  ⌛ 데이터베이스 시작 중..."
    docker-compose up -d db 2>&1 | Out-Null
    Start-Sleep -Seconds 10
    
    if (-not (Wait-ForHealthyContainer "text-to-sql-db" 30)) {
        throw "데이터베이스 시작 실패"
    }

    Write-Log "  ⌛ Redis 시작 중..."
    docker-compose up -d redis 2>&1 | Out-Null
    if (-not (Wait-ForHealthyContainer "text-to-sql-redis" 20)) {
        throw "Redis 시작 실패"
    }

    # 최종 상태 확인
    Write-Log "`n✅ 초기화가 완료되었습니다!"
} catch {
    Write-Log "🚨 초기화 중 오류 발생: $_"
    Write-Log "🔄 정리 작업 실행 중..."
    docker-compose down -v --remove-orphans 2>&1 | Out-Null
    Write-Log "❗ 자세한 오류는 로그 파일을 확인하세요: $logFile"
    Read-Host "Enter 키를 눌러 종료하세요..."
    exit 1
}

Write-Log "`n⚠️ 스크립트 실행 완료. 로그 파일 위치: $logFile"
Read-Host "Enter 키를 눌러 종료하세요..."


# # 현재 스크립트의 절대 경로 가져오기
# $scriptPath = $MyInvocation.MyCommand.Path
# $projectRoot = Split-Path -Parent $scriptPath

# # 관리자 권한 확인
# if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
#     Write-Host "관리자 권한으로 다시 시작합니다..."
#     Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
#     exit
# }

# # 실행 정책 설정
# Set-ExecutionPolicy Bypass -Scope Process -Force

# # 로그 파일 설정
# $logFile = Join-Path $projectRoot "logs\initialize_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
# New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null

# # 로그 기록 함수
# function Write-Log {
#     param($Message)
#     $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
#     Write-Host $logMessage
#     Add-Content -Path $logFile -Value $logMessage
# }

# # 컨테이너 상태 확인 함수
# function Wait-ForHealthyContainer {
#     param (
#         [string]$containerName,
#         [int]$timeoutSeconds = 60
#     )
    
#     $startTime = Get-Date
#     $healthy = $false
    
#     Write-Log "  ⏳ $containerName 상태 확인 중..."
    
#     while (-not $healthy -and ((Get-Date) - $startTime).TotalSeconds -lt $timeoutSeconds) {
#         $status = docker inspect -f '{{.State.Health.Status}}' $containerName 2>$null
#         Write-Log "    📊 현재 상태: $status"
        
#         if ($status -eq "healthy") {
#             $healthy = $true
#             break
#         }
#         Start-Sleep -Seconds 5
#     }
    
#     return $healthy
# }

# # 포트 확인 및 정리 함수
# function Clear-UsedPorts {
#     param (
#         [int[]]$ports = @(3000, 5000, 5433, 6379, 7860)
#     )
#     Write-Log "🔍 사용 중인 포트 확인 중..."
    
#     foreach ($port in $ports) {
#         $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | 
#                   Select-Object -ExpandProperty OwningProcess
#         if ($process) {
#             try {
#                 Stop-Process -Id $process -Force
#                 Write-Log "  ✅ 포트 $port 를 사용하는 프로세스를 종료했습니다."
#             } catch {
#                 Write-Log "  ❌ 포트 $port 를 사용하는 프로세스 종료 실패: $_"
#             }
#         }
#     }
# }

# # Docker Desktop 실행 및 준비 상태 확인 함수 추가
# function Wait-ForDocker {
#     Write-Log "🔄 Docker 상태 확인 중..."
    
#     # Docker Desktop 프로세스 확인
#     $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
#     if (-not $dockerProcess) {
#         Write-Log "  🚀 Docker Desktop 시작 중..."
#         Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
#     }

#     # Docker 엔진 준비 대기
#     $retryCount = 0
#     $maxRetries = 60  # 5분 타임아웃
#     $ready = $false

#     Write-Log "  ⏳ Docker 엔진 준비 대기 중..."
#     while (-not $ready -and $retryCount -lt $maxRetries) {
#         try {
#             $null = docker version
#             $ready = $true
#             Write-Log "  ✅ Docker 엔진이 준비되었습니다."
#         }
#         catch {
#             $retryCount++
#             Write-Log "    🔄 Docker 준비 중... (시도 $retryCount/$maxRetries)"
#             Start-Sleep -Seconds 5
#         }
#     }

#     if (-not $ready) {
#         throw "Docker가 준비 시간을 초과했습니다."
#     }

#     # Docker 네트워크 초기화
#     Write-Log "  🔄 Docker 네트워크 초기화 중..."
#     docker network rm text-to-sql-network -f 2>&1 | Out-Null
#     Start-Sleep -Seconds 2
#     docker network create text-to-sql-network 2>&1 | Out-Null

#     return $ready
# }

# try {
#     Write-Log "🔧 Text-to-SQL 프로젝트 초기화를 시작합니다..."
    
#     # 실행 정책 상태 확인
#     $currentPolicy = Get-ExecutionPolicy
#     Write-Log "  📋 현재 실행 정책: $currentPolicy"
    
#     # 포트 정리
#     Clear-UsedPorts
    
#     # Docker 준비 상태 확인
#     if (-not (Wait-ForDocker)) {
#         throw "Docker 초기화 실패"
#     }
    
#     # 기존 리소스 정리
#     Write-Log "🔄 Docker 환경 초기화 중..."
#     docker-compose down -v --remove-orphans 2>&1 | Out-Null
#     docker system prune -af --volumes 2>&1 | Out-Null
#     Start-Sleep -Seconds 5
    
#     # 서비스 순차적 시작
#     Write-Log "🔄 서비스 시작 중..."
    
#     # DB 시작
#     Write-Log "  ⌛ 데이터베이스 시작 중..."
#     docker-compose up -d db 2>&1 | Out-Null
#     Start-Sleep -Seconds 10
    
#     # DB 상태 확인
#     $maxRetries = 12
#     $retryCount = 0
#     $dbReady = $false
    
#     while (-not $dbReady -and $retryCount -lt $maxRetries) {
#         try {
#             $status = docker inspect -f '{{.State.Health.Status}}' text-to-sql-db 2>$null
#             Write-Log "    📊 DB 상태: $status"
#             if ($status -eq "healthy") {
#                 $dbReady = $true
#                 Write-Log "  ✅ 데이터베이스가 준비되었습니다."
#                 break
#             }
#         }
#         catch {
#             Write-Log "    ⏳ 데이터베이스 준비 중... (시도 $($retryCount + 1)/$maxRetries)"
#         }
#         $retryCount++
#         Start-Sleep -Seconds 5
#     }
    
#     if (-not $dbReady) {
#         throw "데이터베이스 시작 실패"
#     }

#     # Redis 시작
#     Write-Log "  ⌛ Redis 시작 중..."
#     docker-compose up -d redis 2>&1 | Out-Null
#     if (-not (Wait-ForHealthyContainer "text-to-sql-redis" 20)) {
#         throw "Redis 시작 실패"
#     }
    
#     # Langflow 시작
#     Write-Log "  ⌛ Langflow 시작 중..."
#     docker-compose up -d langflow 2>&1 | Out-Null
#     Start-Sleep -Seconds 15
#     if (-not (Wait-ForHealthyContainer "text-to-sql-langflow" 120)) {
#         throw "Langflow 시작 실패"
#     }
    
#     # Backend 시작
#     Write-Log "  ⌛ Backend 시작 중..."
#     docker-compose up -d backend 2>&1 | Out-Null
#     if (-not (Wait-ForHealthyContainer "text-to-sql-backend" 30)) {
#         throw "Backend 시작 실패"
#     }
    
#     # Frontend 시작
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
#     Write-Log "🚨 초기화 중 오류가 발생했습니다: $_"
#     Write-Log "🔄 정리 작업 실행 중..."
#     docker-compose down -v --remove-orphans 2>&1 | Out-Null
#     Write-Log "❗ 자세한 오류 내용은 다음 로그 파일을 확인하세요: $logFile"
#     Read-Host "Enter 키를 눌러 종료하세요..."
#     exit 1
# }

# Write-Log "`n⚠️ 스크립트 실행이 완료되었습니다. 로그 파일 위치: $logFile"
# Read-Host "Enter 키를 눌러 종료하세요..."
