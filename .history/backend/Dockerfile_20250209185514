FROM python:3.10-slim

WORKDIR /app

# 기본 도구 및 PostgreSQL 클라이언트 설치
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    postgresql-client \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 코드 복사
COPY . .

# 시작 스크립트 설정
COPY scripts/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 5000

CMD ["/init.sh"] 