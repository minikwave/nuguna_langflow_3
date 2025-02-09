. .\scripts\utils\logging.ps1

function Initialize-Frontend {
    Write-Log "FRONTEND" "Starting frontend setup" "INFO"
    
    Push-Location frontend
    
    # package.json 체크 및 의존성 설치
    if (-not (Test-Path "package.json")) {
        Write-Log "FRONTEND" "Initializing new React project" "INFO"
        npx create-react-app .
    }
    
    # 필요한 패키지 설치
    $packages = @(
        "@material-ui/core",
        "@material-ui/icons",
        "axios",
        "react-router-dom"
    )
    
    foreach ($package in $packages) {
        Write-Log "FRONTEND" "Installing $package" "INFO"
        npm install $package --save
    }
    
    # 환경 설정 파일 생성
    $env_content = @"
REACT_APP_API_URL=http://localhost:5000
REACT_APP_LANGFLOW_URL=http://localhost:7860
"@
    Set-Content .env $env_content
    
    # 빌드 테스트
    Write-Log "FRONTEND" "Testing build" "INFO"
    npm run build
    
    Pop-Location
} 