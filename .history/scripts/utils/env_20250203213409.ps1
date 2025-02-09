. .\scripts\utils\logging.ps1

function Initialize-Environment {
    param (
        [string]$environment = "development"
    )
    
    Write-Log "ENV" "Initializing environment: $environment" "INFO"
    
    try {
        # 기본 환경 변수 설정
        $envVars = @{
            "DB_USER" = "postgres"
            "DB_PASSWORD" = "password"
            "DB_NAME" = "text_to_sql"
            "DB_PORT" = "5433"
            "FLASK_ENV" = $environment
            "FLASK_APP" = "src.app:create_app"
            "REDIS_URL" = "redis://localhost:6379/0"
            "LANGFLOW_API_URL" = "http://localhost:7860"
        }
        
        # .env 파일 생성
        $envContent = $envVars.GetEnumerator() | ForEach-Object {
            "$($_.Key)=$($_.Value)"
        }
        $envContent | Out-File -FilePath ".env" -Encoding UTF8
        
        # 환경 변수 설정
        foreach ($var in $envVars.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($var.Key, $var.Value, "Process")
        }
        
        Write-Log "ENV" "Environment initialized successfully" "INFO"
        return $envVars
    }
    catch {
        Write-Log "ENV" "Environment initialization failed: $_" "ERROR"
        return $false
    }
} 