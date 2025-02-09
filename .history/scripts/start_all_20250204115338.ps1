. .\scripts\utils\logging.ps1
. .\scripts\utils\monitoring.ps1
. .\scripts\utils\error_handling.ps1

# 서비스 상태 확인 및 초기화
function Initialize-Services {
    # 1. Docker 컨테이너 정리
    Write-Log "INIT" "Cleaning up existing containers" "INFO"
    docker-compose down -v --remove-orphans
    
    # 2. Docker 네트워크 확인
    if (-not (docker network ls --filter name=text-to-sql-network -q)) {
        Write-Log "INIT" "Creating Docker network" "INFO"
        docker network create text-to-sql-network
    }
    
    # 3. 데이터베이스 시작
    Write-Log "INIT" "Starting database" "INFO"
    docker-compose up -d db
    
    # 데이터베이스 준비 대기
    Write-Log "INIT" "Waiting for database" "INFO"
    $retries = 0
    while ($retries -lt 30) {
        try {
            $conn = New-Object System.Net.Sockets.TcpClient
            $conn.Connect("localhost", 5433)
            $conn.Close()
            Write-Log "INIT" "Database is ready" "INFO"
            break
        }
        catch {
            $retries++
            Start-Sleep -Seconds 2
        }
    }
    
    # 4. Redis 시작
    Write-Log "INIT" "Starting Redis" "INFO"
    docker-compose up -d redis
    
    # 5. Langflow 시작
    Write-Log "INIT" "Starting Langflow" "INFO"
    docker-compose up -d langflow
    
    # 6. 백엔드 시작
    Write-Log "INIT" "Starting backend" "INFO"
    docker-compose up -d backend
    
    # 7. 프론트엔드 시작
    Write-Log "INIT" "Starting frontend" "INFO"
    docker-compose up -d frontend
}

# 서비스 초기화 실행
Initialize-Services

# 상태 모니터링 시작
Start-Process powershell -ArgumentList "-NoExit -Command {
    . .\scripts\utils\monitoring.ps1
    . .\scripts\utils\error_handling.ps1
    
    while (`$true) {
        try {
            Clear-Host
            $status = Show-ProjectStatus
            
            # 서비스 자동 복구
            foreach ($service in $status.Keys) {
                if (-not $status[$service].healthy) {
                    Write-Log 'MONITOR' "Service $service is unhealthy, attempting restart" 'WARN'
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