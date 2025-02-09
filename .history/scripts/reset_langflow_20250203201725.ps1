Write-Host "Resetting Langflow..."

# 1. Clean
Write-Host "Cleaning Langflow..."
if (Test-Path "src/services/langflow/__pycache__") {
    Remove-Item "src/services/langflow/__pycache__" -Recurse -Force
}

# 2. Initialize
Write-Host "Initializing Langflow..."
$env:PYTHONPATH = "$PWD;$PWD\src"
python src/scripts/init_langflow.py 