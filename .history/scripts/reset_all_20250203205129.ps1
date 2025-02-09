Write-Host "Resetting all components..."

# PostgreSQL 서비스 중지 (기존 서비스와의 충돌 방지)
Stop-Service postgresql* -ErrorAction SilentlyContinue

# 1. 필수 도구 설치 전 체크
Write-Host "Checking and installing required tools..."
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    refreshenv
}

# PostgreSQL 설치 전 포트 체크
$portCheck = Test-NetConnection -ComputerName localhost -Port 5434 -WarningAction SilentlyContinue
if ($portCheck.TcpTestSucceeded) {
    Write-Host "Warning: Port 5434 is already in use. Please check for existing PostgreSQL installations."
    exit 1
}

# 1. 필수 도구 설치
Write-Host "Installing required tools..."
.\scripts\install_postgres.ps1
.\scripts\install_python_deps.ps1

# 2. 가상환경 설정
if (-not (Test-Path "venv")) {
    Write-Host "Creating virtual environment..."
    python -m venv venv
}

# 가상환경 활성화
. .\venv\Scripts\Activate.ps1

# 3. DB 리셋
Write-Host "Resetting database..."
.\scripts\reset_db.ps1

# 4. 프론트엔드 리셋
Write-Host "Resetting frontend..."
Start-Process powershell -ArgumentList "-NoExit -File scripts\reset_frontend.ps1"

# 5. 백엔드 리셋
Write-Host "Resetting backend..."
Start-Process powershell -ArgumentList "-NoExit -File scripts\reset_backend.ps1"

# 6. Langflow 리셋
Write-Host "Resetting Langflow..."
.\scripts\reset_langflow.ps1

Write-Host "Checking installations..."

# Node.js 확인
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js..."
    choco install nodejs
}

# Python 확인
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Python..."
    choco install python
}

# PostgreSQL 클라이언트 확인
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PostgreSQL client..."
    choco install postgresql
}

# 의존성 설치
pip install -r requirements.txt

Write-Host "All components have been reset!" 