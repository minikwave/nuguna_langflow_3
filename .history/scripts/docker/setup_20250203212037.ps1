. .\scripts\utils\logging.ps1
. .\scripts\utils\env.ps1

function Initialize-DockerEnvironment {
    Write-Log "DOCKER" "Initializing Docker environment" "INFO"
    
    # Docker Compose 파일 생성
    $dockerCompose = @"
version: '3.8'
services:
  db:
    image: postgres:13
    environment:
      POSTGRES_USER: ${env:DB_USER}
      POSTGRES_PASSWORD: ${env:DB_PASSWORD}
      POSTGRES_DB: ${env:DB_NAME}
    ports:
      - "${env:DB_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

  langflow:
    image: langflow/langflow:latest
    ports:
      - "7860:7860"
    environment:
      - LANGFLOW_HOST=0.0.0.0
      - LANGFLOW_PORT=7860

volumes:
  postgres_data:
"@
    Set-Content -Path "docker-compose.yml" -Value $dockerCompose
    
    # Docker 네트워크 생성
    docker network create text-to-sql-network 2>$null
    
    return $true
} 