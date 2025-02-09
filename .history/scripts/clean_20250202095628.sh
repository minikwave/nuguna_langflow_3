#!/bin/bash

# Docker 정리
echo "Cleaning Docker resources..."
docker-compose down -v
docker system prune -af
docker volume prune -f
docker network prune -f

# Python 정리
echo "Cleaning Python resources..."
find . -type f -name "*.pyc" -delete
find . -type d -name "__pycache__" -delete
rm -rf venv
pip cache purge

# Node.js 정리
echo "Cleaning Node.js resources..."
rm -rf frontend/node_modules
rm -rf frontend/build
npm cache clean --force

# 로그 및 임시 파일 정리
echo "Cleaning logs and temporary files..."
rm -rf logs/*
rm -rf /tmp/langflow.pid
rm -rf .pytest_cache

echo "Clean up completed!" 