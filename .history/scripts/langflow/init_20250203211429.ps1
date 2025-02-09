. .\scripts\utils\logging.ps1

function Initialize-Langflow {
    Write-Log "LANGFLOW" "Starting Langflow initialization" "INFO"
    
    # 의존성 확인 및 설치
    $required_packages = @(
        "langflow",
        "langchain",
        "openai",
        "python-dotenv"
    )
    
    foreach ($package in $required_packages) {
        Write-Log "LANGFLOW" "Checking $package" "INFO"
        python -c "import $($package.Replace('-','_'))" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "LANGFLOW" "Installing $package" "INFO"
            pip install $package
        }
    }
    
    # 환경 설정
    $env_content = @"
LANGFLOW_HOST=0.0.0.0
LANGFLOW_PORT=7860
OPENAI_API_KEY=your_api_key_here
"@
    Set-Content .env $env_content
    
    # 설정 테스트
    try {
        $process = Start-Process langflow -ArgumentList "run" -NoNewWindow -PassThru
        Start-Sleep -Seconds 10
        
        $response = Invoke-WebRequest "http://localhost:7860/health" -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Log "LANGFLOW" "Langflow initialized successfully" "INFO"
            Stop-Process $process
            return $true
        }
    }
    catch {
        Write-Log "LANGFLOW" "Langflow initialization failed: $_" "ERROR"
        if ($process) { Stop-Process $process }
        return $false
    }
} 