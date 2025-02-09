. .\scripts\utils\logging.ps1
. .\scripts\utils\monitoring.ps1
. .\scripts\utils\error_handling.ps1

# 서비스 상태 확인
$status = Get-ServiceStatus
if (-not $status.database.port_available) {
    Write-Log "START" "Database is not available" "ERROR"
    exit 1
}

# 병렬 작업을 위한 Job 생성
$jobs = @()

# 1. DB 마이그레이션
$jobs += Start-Job -ScriptBlock {
    . .\scripts\utils\logging.ps1
    Write-Log "START" "Running database migrations" "INFO"
    Invoke-WithRollback "DATABASE" "migrations" {
        .\scripts\setup_db.ps1
    }
}

# 2. 프론트엔드 설정 (병렬)
$jobs += Start-Job -ScriptBlock {
    . .\scripts\utils\logging.ps1
    Write-Log "START" "Setting up frontend" "INFO"
    .\scripts\setup_frontend.ps1
}

# 3. Langflow 초기화 (병렬)
$jobs += Start-Job -ScriptBlock {
    . .\scripts\utils\logging.ps1
    Write-Log "START" "Initializing Langflow" "INFO"
    .\scripts\init_langflow.ps1
}

# 작업 완료 대기
Wait-Job $jobs | Out-Null
$jobs | Receive-Job

# 4. 서비스 시작
Start-Process powershell -ArgumentList "-NoExit -File scripts\start_backend.ps1"
Start-Process powershell -ArgumentList "-NoExit -File scripts\start_frontend.ps1"

# 5. 상태 모니터링 시작 (개선된 버전)
Start-Process powershell -ArgumentList "-NoExit -Command {
    . .\scripts\utils\monitoring.ps1
    . .\scripts\utils\error_handling.ps1
    
    while (`$true) {
        try {
            Clear-Host
            Show-ProjectStatus
            
            # 서비스 자동 복구
            $status = Get-ServiceStatus
            if (-not $status.frontend.healthy) {
                Write-Log 'MONITOR' 'Restarting frontend service' 'WARN'
                Restart-FrontendService
            }
            if (-not $status.backend.healthy) {
                Write-Log 'MONITOR' 'Restarting backend service' 'WARN'
                Restart-BackendService
            }
        } catch {
            Write-Log 'MONITOR' $_.Exception.Message 'ERROR'
        }
        Start-Sleep -Seconds 15
    }
}" 