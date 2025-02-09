# Python 의존성 설치 스크립트
Write-Host "Installing Python dependencies..."

# 최신 버전 psycopg2-binary 사용
pip install --only-binary :all: psycopg2-binary

# 기타 의존성 설치
pip install -r requirements.txt 