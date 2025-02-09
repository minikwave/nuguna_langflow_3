. .\scripts\utils\logging.ps1
. .\scripts\utils\env.ps1

function Initialize-DockerEnvironment {
    Write-Log "DOCKER" "Initializing Docker environment" "INFO"
    
    # Docker Compose 파일 생성
    $dockerCompose = @"
services:
  db:
    image: postgres:13
    container_name: text-to-sql-db
    environment:
      POSTGRES_USER: ${env:DB_USER}
      POSTGRES_PASSWORD: ${env:DB_PASSWORD}
      POSTGRES_DB: ${env:DB_NAME}
    ports:
      - "${env:DB_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${env:DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:alpine
    container_name: text-to-sql-redis
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: text-to-sql-frontend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    depends_on:
      - db
      - redis

volumes:
  postgres_data:
    name: text-to-sql-postgres-data
"@
    Set-Content -Path "docker-compose.yml" -Value $dockerCompose
    
    # Docker 네트워크 생성
    docker network create text-to-sql-network 2>$null
    
    return $true
} 