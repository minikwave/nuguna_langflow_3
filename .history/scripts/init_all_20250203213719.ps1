param (
    [string]$environment = "development"
)

. .\scripts\utils\logging.ps1
. .\scripts\utils\env.ps1
. .\scripts\utils\docker.ps1
. .\scripts\utils\monitoring.ps1
. .\scripts\utils\error_handling.ps1

Write-Host "Starting initialization with environment: $environment" -ForegroundColor Cyan

# 1. 디렉토리 구조 확인
$directories = @(
    "logs",
    "backups",
    "frontend",
    "scripts\utils",
    "scripts\frontend",
    "scripts\backend",
    "scripts\services"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "Created directory: $dir"
    }
}

function Initialize-Project {
    param (
        [string]$environment = "development"
    )
    
    Write-Log "INIT" "Starting project initialization: $environment" "INFO"
    
    try {
        # 1. 환경 초기화
        $envVars = Initialize-Environment -environment $environment
        if (-not $envVars) { 
            Write-Host "Environment initialization failed" -ForegroundColor Red
            throw "Environment initialization failed" 
        }
        
        # 2. Docker 환경 설정
        if (-not (Initialize-DockerEnvironment)) { 
            Write-Host "Docker setup failed" -ForegroundColor Red
            throw "Docker setup failed" 
        }
        
        # 3. 컨테이너 시작
        Write-Host "Starting Docker containers..." -ForegroundColor Yellow
        docker-compose down -v
        docker-compose up -d
        
        # 4. 서비스 상태 확인
        $maxRetries = 30
        $retryCount = 0
        while ($retryCount -lt $maxRetries) {
            $status = Get-ServiceStatus
            if ($status.database.port_available) {
                Write-Host "Database is ready!" -ForegroundColor Green
                break
            }
            Write-Host "Waiting for database... ($retryCount/$maxRetries)"
            $retryCount++
            Start-Sleep -Seconds 1
        }
        
        Write-Host "Project initialization completed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Project initialization failed: $_" -ForegroundColor Red
        return $false
    }
}

# 스크립트 실행
$result = Initialize-Project -environment $environment
if (-not $result) {
    exit 1
} 