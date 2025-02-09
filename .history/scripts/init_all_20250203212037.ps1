. .\scripts\utils\logging.ps1
. .\scripts\utils\env.ps1
. .\scripts\docker\setup.ps1

function Initialize-Project {
    Write-Log "INIT" "Starting project initialization" "INFO"
    
    try {
        # 1. 환경 초기화
        $envVars = Initialize-Environment
        if (-not $envVars) { throw "Environment initialization failed" }
        
        # 2. Docker 환경 설정
        if (-not (Initialize-DockerEnvironment)) { throw "Docker setup failed" }
        
        # 3. 컨테이너 시작
        Write-Log "DOCKER" "Starting containers" "INFO"
        docker-compose down -v
        docker-compose up -d
        
        # 4. 데이터베이스 준비 대기
        $maxRetries = 30
        $retryCount = 0
        while ($retryCount -lt $maxRetries) {
            try {
                $conn = New-Object System.Net.Sockets.TcpClient
                $conn.Connect("localhost", $envVars.DB_PORT)
                $conn.Close()
                Write-Log "DATABASE" "Database is ready" "INFO"
                break
            }
            catch {
                $retryCount++
                Start-Sleep -Seconds 1
            }
        }
        
        # 5. 프론트엔드 초기화
        Write-Log "FRONTEND" "Initializing frontend" "INFO"
        if (-not (Initialize-FrontendComplete)) { throw "Frontend initialization failed" }
        
        # 6. 백엔드 초기화
        Write-Log "BACKEND" "Initializing backend" "INFO"
        if (-not (Initialize-Backend)) { throw "Backend initialization failed" }
        
        Write-Log "INIT" "Project initialization completed successfully" "INFO"
        return $true
    }
    catch {
        Write-Log "INIT" "Project initialization failed: $_" "ERROR"
        return $false
    }
} 