#!/bin/bash

# 데이터베이스 마이그레이션 대기
echo "Waiting for database..."
while ! nc -z db 5432; do
  sleep 1
done

# Redis 대기
echo "Waiting for Redis..."
while ! nc -z redis 6379; do
  sleep 1
done

# Langflow 대기
echo "Waiting for Langflow..."
while ! nc -z langflow 7860; do
  sleep 1
done

# 데이터베이스 마이그레이션
echo "Running database migrations..."
python -m alembic upgrade head

# Langflow 초기화
echo "Initializing Langflow..."
python src/scripts/init_langflow.py

# 애플리케이션 실행
echo "Starting application..."
gunicorn -w 4 -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:5000 