. .\scripts\utils\logging.ps1

function Initialize-Environment {
    param (
        [string]$environment = "development"
    )
    
    Write-Log "ENV" "Initializing environment: $environment" "INFO"
    
    # 기본 환경 변수 설정
    $env:DB_USER = "postgres"
    $env:DB_PASSWORD = "postgres"
    $env:DB_NAME = "text_to_sql"
    $env:DB_PORT = "5433"
    
    # 환경별 설정
    switch ($environment) {
        "development" {
            $env:FLASK_ENV = "development"
            $env:DEBUG = "true"
        }
        "production" {
            $env:FLASK_ENV = "production"
            $env:DEBUG = "false"
        }
    }
    
    Write-Log "ENV" "Environment initialized successfully" "INFO"
    return $true
} 