. .\scripts\utils\logging.ps1

function Initialize-Environment {
    param (
        [string]$environment = "development"
    )
    
    Write-Log "ENV" "Initializing environment: $environment" "INFO"
    
    # 기본 환경 변수
    $envVars = @{
        "PYTHONPATH" = "$PWD;$PWD\src"
        "FLASK_APP" = "src.app:create_app"
        "FLASK_ENV" = $environment
        "DB_PORT" = "5433"  # 통일된 포트
        "DB_USER" = "user"
        "DB_PASSWORD" = "password"
        "DB_NAME" = "text_to_sql"
    }
    
    # 환경 변수 설정
    foreach ($key in $envVars.Keys) {
        [System.Environment]::SetEnvironmentVariable($key, $envVars[$key], [System.EnvironmentVariableTarget]::Process)
        Write-Log "ENV" "Set $key = $($envVars[$key])" "DEBUG"
    }
    
    # .env 파일 생성
    $envContent = @"
FLASK_APP=$($envVars.FLASK_APP)
FLASK_ENV=$($envVars.FLASK_ENV)
DATABASE_URL=postgresql://$($envVars.DB_USER):$($envVars.DB_PASSWORD)@localhost:$($envVars.DB_PORT)/$($envVars.DB_NAME)
REDIS_URL=redis://localhost:6379/0
LANGFLOW_API_URL=http://localhost:7860
"@
    Set-Content -Path ".env" -Value $envContent -Encoding UTF8
    
    return $envVars
} 