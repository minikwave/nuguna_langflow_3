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
        
        # 기존 컨테이너 정리
        Write-Host "Cleaning up existing containers..." -ForegroundColor Yellow
        docker-compose down -v --remove-orphans --verbose
        
        # Docker 네트워크 생성
        Write-Host "Creating Docker network..." -ForegroundColor Yellow
        docker network create text-to-sql-network --verbose 2>$null
        
        # Docker Compose 파일 생성
        Write-Host "Generating docker-compose.yml..." -ForegroundColor Yellow
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
    command: postgres -c logging_collector=on -c log_directory=/var/log/postgresql -c log_filename=postgresql-%Y-%m-%d_%H%M%S.log

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
    command: redis-server --loglevel verbose

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
    depends_on:
      - db
      - redis
    volumes:
      - ./frontend/nginx/logs:/var/log/nginx

volumes:
  postgres_data:
    name: text-to-sql-postgres-data
"@
        Set-Content -Path "docker-compose.yml" -Value $dockerCompose
        
        # 이미지 빌드
        Write-Host "Building Docker images..." -ForegroundColor Yellow
        docker-compose build --no-cache --verbose
        
        # 컨테이너 실행
        Write-Host "Starting containers..." -ForegroundColor Yellow
        docker-compose up -d --verbose
        
        # 컨테이너 상태 확인
        Write-Host "`nChecking container status:" -ForegroundColor Cyan
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # 컨테이너 로그 확인
        Write-Host "`nContainer logs:" -ForegroundColor Cyan
        docker-compose logs --tail=20
        
        Write-Log "DOCKER" "Docker environment initialized successfully" "INFO"
        return $true
    }
    catch {
        Write-Log "DOCKER" "Docker initialization failed: $_" "ERROR"
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} 