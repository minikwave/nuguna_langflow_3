. .\scripts\utils\logging.ps1
. .\scripts\utils\error_handling.ps1

function Initialize-DockerEnvironment {
    Write-Log "DOCKER" "Initializing Docker environment" "INFO"
    
    try {
        # Docker 실행 상태 확인
        docker version | Out-Null
        if (-not $?) {
            throw "Docker is not running"
        }
        
        # Docker Compose 확인
        docker-compose version | Out-Null
        if (-not $?) {
            throw "Docker Compose is not available"
        }
        
        # 기존 컨테이너 정리
        Write-Log "DOCKER" "Cleaning up existing containers" "INFO"
        docker-compose down -v --remove-orphans
        
        # 이미지 빌드
        Write-Log "DOCKER" "Building Docker images" "INFO"
        docker-compose build --no-cache
        
        Write-Log "DOCKER" "Docker environment initialized successfully" "INFO"
        return $true
    }
    catch {
        Write-Log "DOCKER" "Docker initialization failed: $_" "ERROR"
        return $false
    }
}

function Test-DockerHealth {
    param (
        [string]$containerName,
        [int]$timeoutSeconds = 60
    )
    
    Write-Log "DOCKER" "Checking health for container: $containerName" "INFO"
    
    $retries = 0
    while ($retries -lt $timeoutSeconds) {
        $health = docker inspect --format='{{.State.Health.Status}}' $containerName 2>$null
        
        if ($health -eq "healthy") {
            Write-Log "DOCKER" "Container $containerName is healthy" "INFO"
            return $true
        }
        
        $retries++
        Start-Sleep -Seconds 1
    }
    
    Write-Log "DOCKER" "Container $containerName health check timed out" "ERROR"
    return $false
}

function Stop-DockerServices {
    Write-Log "DOCKER" "Stopping Docker services" "INFO"
    
    try {
        docker-compose down -v --remove-orphans
        Write-Log "DOCKER" "Docker services stopped successfully" "INFO"
        return $true
    }
    catch {
        Write-Log "DOCKER" "Failed to stop Docker services: $_" "ERROR"
        return $false
    }
} 