. .\scripts\utils\logging.ps1
. .\scripts\utils\monitoring.ps1
. .\scripts\utils\error_handling.ps1
. .\scripts\utils\port_management.ps1

# 서비스 포트 매핑
$SERVICE_PORTS = @{
    'frontend' = 3000
    'backend' = 5000
    'database' = 5433
    'redis' = 6379
    'langflow' = 7860
}

function Initialize-Services {
    # Docker 네트워크 확인
    if (-not (docker network ls --filter name=text-to-sql-network -q)) {
        Write-Log "INIT" "Creating Docker network" "INFO"
        docker network create text-to-sql-network
    }
    
    # 컨테이너 정리
    Write-Log "INIT" "Cleaning up existing containers" "INFO"
    docker-compose down -v --remove-orphans
    
    try {
        # 데이터베이스 먼저 시작
        Write-Log "INIT" "Starting database" "INFO"
        docker-compose up -d db
        Wait-ForPort -Port $SERVICE_PORTS['database'] -Service "database" -Timeout 30
        
        # Redis 시작
        Write-Log "INIT" "Starting Redis" "INFO"
        docker-compose up -d redis
        Wait-ForPort -Port $SERVICE_PORTS['redis'] -Service "redis" -Timeout 15
        
        # Langflow 시작 전 이미지 확인
        Write-Log "INIT" "Checking Langflow image" "INFO"
        if (-not (docker images logspace/langflow -q)) {
            Write-Log "INIT" "Pulling Langflow image" "INFO"
            docker pull logspace/langflow:latest
        }
        docker-compose up -d langflow
        Wait-ForPort -Port $SERVICE_PORTS['langflow'] -Service "langflow" -Timeout 30
        
        # 나머지 서비스 시작
        Write-Log "INIT" "Starting remaining services" "INFO"
        docker-compose up -d
    }
    catch {
        Write-Log "INIT" "Service initialization failed: $_" "ERROR"
        throw
    }
}

function Wait-ForPort {
    param (
        [int]$Port,
        [string]$Service,
        [int]$Timeout = 30
    )
    
    Write-Log "INIT" "Waiting for $Service to be available on port $Port" "INFO"
    $retries = 0
    while ($retries -lt $Timeout) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect("localhost", $Port)
            $tcpClient.Close()
            Write-Log "INIT" "$Service is ready on port $Port" "INFO"
            return $true
        }
        catch {
            $retries++
            Start-Sleep -Seconds 1
        }
    }
    throw "Timeout waiting for $Service to be available on port $Port"
}

# 메인 실행 부분
try {
    Initialize-Services
    
    # 상태 모니터링 시작
    Start-Process powershell -ArgumentList "-NoExit -Command {
        . .\scripts\utils\monitoring.ps1
        . .\scripts\utils\error_handling.ps1
        . .\scripts\utils\port_management.ps1
        
        while (`$true) {
            try {
                Clear-Host
                $status = Show-ProjectStatus
                
                # 서비스 및 포트 상태 확인
                foreach ($service in $status.Keys) {
                    if (-not $status[$service].port_available) {
                        Write-Log 'MONITOR' `"Port $($SERVICE_PORTS[$service]) for $service is not available`" 'WARN'
                        Clear-PortIfInUse -Port $SERVICE_PORTS[$service] -ServiceName $service
                        docker-compose restart $service
                    }
                }
            }
            catch {
                Write-Log 'MONITOR' $_.Exception.Message 'ERROR'
            }
            Start-Sleep -Seconds 15
        }
    }"
}
catch {
    Write-Log "INIT" "Initialization failed: $_" "ERROR"
    exit 1
} 