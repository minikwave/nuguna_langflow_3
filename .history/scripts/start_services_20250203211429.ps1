# 서비스 시작 스크립트
. .\scripts\utils\logging.ps1

Write-Log "SERVICES" "Starting all services..." "INFO"

# 환경 변수 설정
$env:PYTHONPATH = "$PWD;$PWD\src"
$env:FLASK_APP = "src.app:create_app"
$env:FLASK_ENV = "development"

# PostgreSQL 서비스 상태 확인 및 시작
$pgService = Get-Service postgresql-x64-13 -ErrorAction SilentlyContinue
if ($pgService.Status -ne 'Running') {
    Write-Log "POSTGRESQL" "Starting PostgreSQL service..." "INFO"
    Start-Service postgresql-x64-13
    Start-Sleep -Seconds 5
}

# 백엔드 시작
Write-Log "BACKEND" "Starting Flask backend..." "INFO"
Start-Process python -ArgumentList "-m flask run --host=0.0.0.0 --port=5000" -NoNewWindow

# 프론트엔드 시작
Write-Log "FRONTEND" "Starting React frontend..." "INFO"
Push-Location frontend
Start-Process npm -ArgumentList "start" -NoNewWindow
Pop-Location

# Langflow 시작
Write-Log "LANGFLOW" "Starting Langflow service..." "INFO"
Start-Process langflow -ArgumentList "run" -NoNewWindow

Write-Log "SERVICES" "All services started successfully" "INFO" 