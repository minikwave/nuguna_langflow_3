Write-Host "Resetting backend..."

# 1. Clean
Write-Host "Cleaning backend..."
if (Test-Path "__pycache__") {
    Remove-Item "__pycache__" -Recurse -Force
    Write-Host "Cleaned Python cache"
}

# 2. Start
Write-Host "Starting backend..."
$env:FLASK_APP = "src.app:create_app()"
$env:FLASK_ENV = "development"
$env:PYTHONPATH = "$PWD;$PWD\src"

python -m flask run --host=0.0.0.0 --port=5000 