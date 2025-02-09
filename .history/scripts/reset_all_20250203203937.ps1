Write-Host "Resetting all components..."

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