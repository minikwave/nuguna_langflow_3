Write-Host "Resetting frontend..."

# 1. Clean
Write-Host "Cleaning frontend..."
Push-Location frontend
if (Test-Path "build") {
    Remove-Item "build" -Recurse -Force
    Write-Host "Cleaned build directory"
}
if (Test-Path "node_modules") {
    Remove-Item "node_modules" -Recurse -Force
    Write-Host "Cleaned node_modules"
}
Pop-Location

# 2. Setup
Write-Host "Setting up frontend..."
Push-Location frontend
npm install
npm run build
npm start
Pop-Location 