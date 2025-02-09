. .\scripts\utils\logging.ps1

function Update-Dependencies {
    param (
        [switch]$CheckOnly
    )
    
    $updates = @{
        frontend = @()
        backend = @()
    }
    
    # 프런트엔드 의존성 체크
    Push-Location frontend
    try {
        $outdated = npm outdated --json | ConvertFrom-Json
        foreach ($package in $outdated.PSObject.Properties) {
            $updates.frontend += @{
                name = $package.Name
                current = $package.Value.current
                wanted = $package.Value.wanted
                latest = $package.Value.latest
            }
        }
        
        if (-not $CheckOnly -and $updates.frontend.Count -gt 0) {
            Write-Log "DEPS" "Updating frontend dependencies" "INFO"
            npm update
        }
    }
    catch {
        Write-Log "DEPS" "Frontend dependency check failed: $_" "ERROR"
    }
    finally {
        Pop-Location
    }
    
    # 백엔드 의존성 체크
    try {
        $requirements = Get-Content requirements.txt
        foreach ($req in $requirements) {
            if ($req -match '^([^=]+)==(.+)$') {
                $package = $matches[1]
                $version = $matches[2]
                $latest = pip index versions $package --pre | Select-Object -First 1
                if ($latest -ne $version) {
                    $updates.backend += @{
                        name = $package
                        current = $version
                        latest = $latest
                    }
                }
            }
        }
        
        if (-not $CheckOnly -and $updates.backend.Count -gt 0) {
            Write-Log "DEPS" "Updating backend dependencies" "INFO"
            pip install -r requirements.txt --upgrade
        }
    }
    catch {
        Write-Log "DEPS" "Backend dependency check failed: $_" "ERROR"
    }
    
    return $updates
} 