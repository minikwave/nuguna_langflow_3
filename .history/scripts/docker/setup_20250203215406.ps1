. .\scripts\utils\logging.ps1
. .\scripts\utils\env.ps1

function Initialize-DockerEnvironment {
    Write-Log "DOCKER" "Initializing Docker environment" "INFO"
    
    try {
        # Docker 실행 상태 상세 확인
        Write-Host "Checking Docker status..." -ForegroundColor Yellow
        $dockerVersion = docker version --format '{{.Server.Version}}'
        Write-Host "Docker version: $dockerVersion" -ForegroundColor Green
        
        # Docker Compose 상세 확인
        Write-Host "Checking Docker Compose..." -ForegroundColor Yellow
        $composeVersion = docker-compose version --short
        Write-Host "Docker Compose version: $composeVersion" -ForegroundColor Green
        
        # Docker Compose 파일 생성
        Write-Host "Generating docker-compose.yml..." -ForegroundColor Yellow
        $dockerCompose = @"
services:
  db:
    image: postgres:13
    container_name: text-to-sql-db
    environment:
      POSTGRES_USER: `${DB_USER}
      POSTGRES_PASSWORD: `${DB_PASSWORD}
      POSTGRES_DB: `${DB_NAME}
    ports:
      - "`${DB_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U `${DB_USER}"]
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

  langflow:
    image: langflow/langflow:latest
    container_name: text-to-sql-langflow
    ports:
      - "7860:7860"
    environment:
      - LANGFLOW_AUTO_LOGIN=false
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7860/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build:
      context: .
      dockerfile: backend/Dockerfile
    container_name: text-to-sql-backend
    environment:
      - FLASK_APP=src.app:create_app
      - FLASK_ENV=development
      - DATABASE_URL=postgresql://`${DB_USER}:`${DB_PASSWORD}@db:5432/`${DB_NAME}
      - REDIS_URL=redis://redis:6379/0
      - LANGFLOW_API_URL=http://langflow:7860
    ports:
      - "5000:5000"
    depends_on:
      - db
      - redis
      - langflow

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: text-to-sql-frontend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - REACT_APP_API_URL=http://localhost:5000
      - REACT_APP_LANGFLOW_URL=http://localhost:7860
    depends_on:
      - backend
    volumes:
      - ./frontend/nginx/logs:/var/log/nginx

volumes:
  postgres_data:
    name: text-to-sql-postgres-data
"@
        Set-Content -Path "docker-compose.yml" -Value $dockerCompose
        
        # 기존 컨테이너 정리
        Write-Host "Cleaning up existing containers..." -ForegroundColor Yellow
        docker-compose down -v --remove-orphans --verbose
        
        # Docker 네트워크 생성
        Write-Host "Creating Docker network..." -ForegroundColor Yellow
        docker network create text-to-sql-network --verbose 2>$null
        
        # Langflow 이미지 풀
        Write-Host "Pulling Langflow image..." -ForegroundColor Yellow
        docker pull langflow/langflow:latest --verbose
        
        # 이미지 강제 재빌드
        Write-Host "Building Docker images..." -ForegroundColor Yellow
        docker-compose build --no-cache --pull --verbose
        
        # 컨테이너 실행
        Write-Host "Starting containers..." -ForegroundColor Yellow
        docker-compose up -d --force-recreate --verbose
        
        # 컨테이너 상태 확인
        Write-Host "`nContainer Status:" -ForegroundColor Cyan
        docker ps -a
        
        # 컨테이너 로그 확인
        Write-Host "`nContainer Logs:" -ForegroundColor Cyan
        docker-compose logs
        
        return $true
    }
    catch {
        Write-Log "DOCKER" "Docker initialization failed: $_" "ERROR"
        Write-Host "Full error details: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} 