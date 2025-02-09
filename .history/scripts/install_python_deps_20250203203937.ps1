# Python 의존성 설치 스크립트
Write-Host "Installing Python dependencies..."

# Visual C++ 빌드 도구 설치
Write-Host "Installing Visual C++ Build Tools..."
choco install visualstudio2019buildtools --package-parameters "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64" -y
refreshenv

# psycopg2 바이너리 버전 설치
Write-Host "Installing psycopg2-binary..."
pip install --only-binary :all: psycopg2-binary==2.9.1

# 기타 의존성 설치
Write-Host "Installing other dependencies..."
pip install -r requirements.txt 