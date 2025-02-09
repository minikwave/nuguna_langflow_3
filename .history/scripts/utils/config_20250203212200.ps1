. .\scripts\utils\logging.ps1

function Get-EnvironmentConfig {
    param (
        [string]$environment = "development"
    )
    
    $configs = @{
        "development" = @{
            "DB_PORT" = "5433"
            "ENABLE_DEBUG" = $true
            "LOG_LEVEL" = "DEBUG"
            "CORS_ORIGINS" = "http://localhost:3000"
        }
        "production" = @{
            "DB_PORT" = "5432"
            "ENABLE_DEBUG" = $false
            "LOG_LEVEL" = "INFO"
            "CORS_ORIGINS" = "https://your-domain.com"
        }
        "testing" = @{
            "DB_PORT" = "5435"
            "ENABLE_DEBUG" = $true
            "LOG_LEVEL" = "DEBUG"
            "CORS_ORIGINS" = "http://localhost:3000"
        }
    }
    
    if (-not $configs.ContainsKey($environment)) {
        Write-Log "CONFIG" "Invalid environment: $environment" "ERROR"
        throw "Invalid environment specified"
    }
    
    return $configs[$environment]
} 