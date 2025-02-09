. .\scripts\utils\logging.ps1
. .\scripts\utils\env.ps1
. .\scripts\utils\docker.ps1
. .\scripts\utils\monitoring.ps1
. .\scripts\utils\error_handling.ps1

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
        
        # 4. 서비스 상태 확인
        $maxRetries = 30
        $retryCount = 0
        while ($retryCount -lt $maxRetries) {
            $status = Get-ServiceStatus
            if ($status.database.port_available) {
                Write-Log "INIT" "Database is ready" "INFO"
                break
            }
            $retryCount++
            Start-Sleep -Seconds 1
        }
        
        if ($retryCount -eq $maxRetries) {
            throw "Database failed to start within timeout period"
        }
        
        # 5. 프론트엔드 초기화
        Write-Log "FRONTEND" "Initializing frontend" "INFO"
        if (-not (Initialize-FrontendComplete)) { throw "Frontend initialization failed" }
        
        # 6. 백엔드 초기화
        Write-Log "BACKEND" "Initializing backend" "INFO"
        if (-not (Initialize-Backend)) { throw "Backend initialization failed" }
        
        # 7. 초기 백업 생성
        Write-Log "INIT" "Creating initial backup" "INFO"
        $backupPath = Backup-Project
        Write-Log "INIT" "Initial backup created at: $backupPath" "INFO"
        
        Write-Log "INIT" "Project initialization completed successfully" "INFO"
        return $true
    }
    catch {
        Write-Log "INIT" "Project initialization failed: $_" "ERROR"
        return $false
    }
} 