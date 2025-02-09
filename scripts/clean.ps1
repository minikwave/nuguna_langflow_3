# clean.ps1
Write-Host "Cleaning up resources..."

# Docker 정리
Write-Host "Cleaning Docker resources..."
docker-compose down -v
docker system prune -af
docker volume prune -f
docker network prune -f

# Python 정리
Write-Host "Cleaning Python resources..."
Get-ChildItem -Path . -Include *.pyc -Recurse | Remove-Item
Get-ChildItem -Path . -Include __pycache__ -Recurse | Remove-Item -Recurse
Remove-Item -Path venv -Recurse -Force -ErrorAction SilentlyContinue
pip cache purge

# Node.js 정리
Write-Host "Cleaning Node.js resources..."
Remove-Item -Path frontend\node_modules -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path frontend\build -Recurse -Force -ErrorAction SilentlyContinue
npm cache clean --force

# 로그 및 임시 파일 정리
Write-Host "Cleaning logs and temporary files..."
Remove-Item -Path logs\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $env:TEMP\langflow.pid -Force -ErrorAction SilentlyContinue
Remove-Item -Path .pytest_cache -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Clean up completed!" 