. .\scripts\utils\logging.ps1
. .\scripts\utils\monitoring.ps1
. .\scripts\utils\error_handling.ps1

# 서비스 상태 확인
$status = Get-ServiceStatus
if (-not $status.database.port_available) {
    Write-Log "START" "Database is not available" "ERROR"
    exit 1
}

# 1. 데이터베이스 마이그레이션
Write-Log "START" "Running database migrations" "INFO"
Invoke-WithRollback "DATABASE" "migrations" {
    .\scripts\setup_db.ps1
}

# 2. 프론트엔드 설정
Write-Log "START" "Setting up frontend" "INFO"
.\scripts\setup_frontend.ps1

# 3. 백엔드 시작
Write-Log "START" "Starting backend service" "INFO"
Start-Process powershell -ArgumentList "-NoExit -File scripts\start_backend.ps1"

# 4. 프론트엔드 시작 (새 창에서)
Write-Log "START" "Starting frontend service" "INFO"
Start-Process powershell -ArgumentList "-NoExit -File scripts\start_frontend.ps1"

# 5. Langflow 초기화
Write-Log "START" "Initializing Langflow" "INFO"
.\scripts\init_langflow.ps1

# 6. 상태 모니터링 시작
Write-Log "START" "Starting status monitoring" "INFO"
Start-Process powershell -ArgumentList "-NoExit -Command {
    . .\scripts\utils\monitoring.ps1
    while (`$true) {
        Clear-Host
        Show-ProjectStatus
        Start-Sleep -Seconds 30
    }
}" 