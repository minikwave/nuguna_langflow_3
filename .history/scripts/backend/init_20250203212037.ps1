. .\scripts\utils\logging.ps1

function Initialize-Backend {
    Write-Log "BACKEND" "Initializing backend" "INFO"
    
    try {
        # 1. Python 가상환경 설정
        if (-not (Test-Path "venv")) {
            python -m venv venv
        }
        . .\venv\Scripts\Activate.ps1
        
        # 2. 의존성 설치
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        
        # 3. 마이그레이션
        Write-Log "BACKEND" "Running migrations" "INFO"
        alembic upgrade head
        
        return $true
    }
    catch {
        Write-Log "BACKEND" "Backend initialization failed: $_" "ERROR"
        return $false
    }
} 