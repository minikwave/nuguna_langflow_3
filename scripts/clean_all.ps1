# 1. DB 정리
.\scripts\clean_db.ps1

# 2. 프론트엔드 정리
.\scripts\clean_frontend.ps1

# 3. 임시 파일 정리
if (Test-Path "logs") {
    Remove-Item "logs/*" -Force
    Write-Host "Cleaned logs"
}

if (Test-Path "__pycache__") {
    Remove-Item "__pycache__" -Recurse -Force
    Write-Host "Cleaned Python cache"
}

Write-Host "Clean completed" 