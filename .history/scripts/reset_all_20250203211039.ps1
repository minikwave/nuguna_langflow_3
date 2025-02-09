Write-Host "Resetting all components..."

# 1. 환경 준비
$env:PYTHONPATH = "$PWD;$PWD\src"
if (-not (Test-Path "src")) {
    New-Item -ItemType Directory -Path "src"
}

# 2. 데이터베이스 설정
if (-not (Test-Dependencies "postgresql13")) {
    .\scripts\install_postgres.ps1
} else {
    Write-Host "PostgreSQL already installed, checking service..."
    Start-Service postgresql-x64-13
}

# 3. Python 가상환경
if (-not (Test-Path "venv")) {
    python -m venv venv
}
. .\venv\Scripts\Activate.ps1

# 4. 컴포넌트 리셋 (병렬 실행)
$jobs = @()
$jobs += Start-Job -ScriptBlock { 
    Set-Location $using:PWD
    .\scripts\reset_frontend.ps1 
}
$jobs += Start-Job -ScriptBlock { 
    Set-Location $using:PWD
    .\scripts\reset_backend.ps1 
}
$jobs += Start-Job -ScriptBlock { 
    Set-Location $using:PWD
    .\scripts\reset_langflow.ps1 
}

# 작업 완료 대기
Wait-Job $jobs
Receive-Job $jobs

Write-Host "All components have been reset!" 