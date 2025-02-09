Write-Host "Cleaning frontend..."

Push-Location frontend

# 1. 빌드 산출물 정리
if (Test-Path "build") {
    Remove-Item "build" -Recurse -Force
    Write-Host "Cleaned build directory"
}

# 2. node_modules 정리
if (Test-Path "node_modules") {
    Remove-Item "node_modules" -Recurse -Force
    Write-Host "Cleaned node_modules"
}

Pop-Location 