Write-Host "Resetting all components..."

# 1. DB 리셋
Write-Host "Resetting database..."
.\scripts\reset_db.ps1

# 2. 프론트엔드 리셋 (새 창에서)
Write-Host "Resetting frontend..."
Start-Process powershell -ArgumentList "-NoExit -File scripts\reset_frontend.ps1"

# 3. 백엔드 리셋 (새 창에서)
Write-Host "Resetting backend..."
Start-Process powershell -ArgumentList "-NoExit -File scripts\reset_backend.ps1"

# 4. Langflow 리셋
Write-Host "Resetting Langflow..."
.\scripts\reset_langflow.ps1

Write-Host "All components have been reset!" 