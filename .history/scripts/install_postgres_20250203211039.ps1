# PostgreSQL 설치 스크립트
Write-Host "Installing PostgreSQL..."

# PostgreSQL 설치 전 환경 변수 설정
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

# Chocolatey 설치 확인 및 설치
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    refreshenv
}

# PostgreSQL 설치 (포트 5434 지정)
Write-Host "Installing PostgreSQL using Chocolatey..."
choco install postgresql13 --params '/Password:password /Port:5434' -y

# 환경 변수 새로 고침 및 대기
refreshenv
Start-Sleep -Seconds 10

# PostgreSQL bin 디렉토리를 PATH에 추가
$pgPath = "C:\Program Files\PostgreSQL\13\bin"
if (-not ($env:Path -like "*$pgPath*")) {
    $env:Path = "$pgPath;" + $env:Path
    [Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")
}

# PostgreSQL 서비스 재시작
Write-Host "Restarting PostgreSQL service..."
Restart-Service postgresql-x64-13 -Force

# DB 생성 전 대기
Start-Sleep -Seconds 5

# DB 및 사용자 생성
Write-Host "Creating database and user..."
$env:PGPASSWORD = "password"
$env:PGPORT = "5434"
& "$pgPath\psql" -U postgres -p 5434 -c "CREATE DATABASE text_to_sql;"
& "$pgPath\psql" -U postgres -p 5434 -c "CREATE USER user WITH PASSWORD 'password';"
& "$pgPath\psql" -U postgres -p 5434 -c "GRANT ALL PRIVILEGES ON DATABASE text_to_sql TO user;" 