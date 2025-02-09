param (
    [string]$environment = "development"
)

. .\scripts\utils\logging.ps1
. .\scripts\utils\env.ps1
. .\scripts\utils\docker.ps1
. .\scripts\utils\monitoring.ps1
. .\scripts\utils\error_handling.ps1
. .\scripts\utils\windows_setup.ps1

Write-Host "Starting initialization with environment: $environment" -ForegroundColor Cyan

# 1. 디렉토리 구조 확인
$directories = @(
    "logs",
    "backups",
    "frontend",
    "scripts\utils",
    "scripts\frontend",
    "scripts\backend",
    "scripts\services"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "Created directory: $dir"
    }
}

# frontend 디렉토리 초기화 부분 추가
if (-not (Test-Path "frontend")) {
    Write-Host "Initializing frontend project..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "frontend"
    Push-Location frontend
    
    # package.json 생성
    @"
{
  "name": "text-to-sql-frontend",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  }
}
"@ | Out-File -FilePath "package.json" -Encoding UTF8

    # 기본 파일 생성
    New-Item -ItemType Directory -Path "src"
    New-Item -ItemType Directory -Path "public"
    
    Pop-Location
}

function Initialize-Project {
    param (
        [string]$environment = "development"
    )
    
    Write-Log "INIT" "Starting project initialization: $environment" "INFO"
    
    try {
        # 1. 환경 검증
        if (-not (Test-Prerequisites)) {
            throw "Prerequisites check failed"
        }
        
        # 2. 환경 초기화
        $envVars = Initialize-Environment -environment $environment
        if (-not $envVars) { 
            throw "Environment initialization failed" 
        }
        
        # 3. Docker 환경 설정
        if (-not (Initialize-DockerEnvironment)) { 
            throw "Docker setup failed" 
        }
        
        # 4. 서비스 시작 및 상태 확인
        Start-ServicesWithHealthCheck
        
        Write-Log "INIT" "Project initialization completed successfully" "INFO"
        return $true
    }
    catch {
        Write-Log "INIT" "Project initialization failed: $_" "ERROR"
        Start-Rollback
        return $false
    }
}

try {
    # Windows 환경 초기화
    Initialize-WindowsEnvironment
    
    # Docker Desktop 실행 상태 확인
    $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerProcess) {
        Write-Log "INIT" "Starting Docker Desktop" "INFO"
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        Start-Sleep -Seconds 30  # Docker Desktop 시작 대기
    }
    
    # 기존 초기화 로직 실행
    Initialize-Project -environment $environment
}
catch {
    Write-Log "INIT" "Initialization failed: $_" "ERROR"
    exit 1
} 