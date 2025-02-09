param (
    [string]$environment = "development"
)

. .\scripts\utils\logging.ps1
. .\scripts\utils\env.ps1
. .\scripts\utils\docker.ps1
. .\scripts\utils\monitoring.ps1
. .\scripts\utils\error_handling.ps1

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
        # 1. 환경 초기화
        $envVars = Initialize-Environment -environment $environment
        if (-not $envVars) { 
            Write-Host "Environment initialization failed" -ForegroundColor Red
            throw "Environment initialization failed" 
        }
        
        # 2. Docker 환경 설정
        if (-not (Initialize-DockerEnvironment)) { 
            Write-Host "Docker setup failed" -ForegroundColor Red
            throw "Docker setup failed" 
        }
        
        # 3. 컨테이너 시작
        Write-Host "Starting Docker containers..." -ForegroundColor Yellow
        docker-compose down -v
        docker-compose up -d
        
        # 4. 서비스 상태 확인
        $maxRetries = 30
        $retryCount = 0
        while ($retryCount -lt $maxRetries) {
            try {
                $conn = New-Object System.Net.Sockets.TcpClient
                $conn.Connect("localhost", $env:DB_PORT)
                $conn.Close()
                Write-Host "Database is ready!" -ForegroundColor Green
                break
            }
            catch {
                Write-Host "Waiting for database... ($retryCount/$maxRetries)"
                $retryCount++
                Start-Sleep -Seconds 1
            }
        }
        
        Write-Host "Project initialization completed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Project initialization failed: $_" -ForegroundColor Red
        return $false
    }
}

# 스크립트 실행
$result = Initialize-Project -environment $environment
if (-not $result) {
    exit 1
} 