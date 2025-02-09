. .\scripts\utils\logging.ps1
. .\scripts\utils\monitoring.ps1
. .\scripts\utils\backup.ps1
. .\scripts\utils\dependencies.ps1
. .\scripts\utils\error_handling.ps1

function Show-ProjectStatus {
    Write-Log "MANAGE" "Checking project status" "INFO"
    
    $status = Get-ServiceStatus
    
    Write-Host "`nProject Status:" -ForegroundColor Cyan
    foreach ($service in $status.Keys) {
        Write-Host "`n$($service.ToUpper()):" -ForegroundColor Yellow
        Write-Host "Running: $($status[$service].running)"
        Write-Host "Port Available: $($status[$service].port_available)"
        Write-Host "Health: $($status[$service].health)"
        if ($status[$service].details) {
            Write-Host "Details: $($status[$service].details)"
        }
    }
}

function Start-AutoBackup {
    param (
        [int]$intervalHours = 24
    )
    
    Write-Log "MANAGE" "Starting automatic backup (Interval: $intervalHours hours)" "INFO"
    
    while ($true) {
        try {
            $backupPath = Backup-Project
            Write-Log "MANAGE" "Backup created at: $backupPath" "INFO"
        }
        catch {
            Write-Log "MANAGE" "Backup failed: $_" "ERROR"
        }
        
        Start-Sleep -Seconds ($intervalHours * 3600)
    }
}

function Update-Project {
    param (
        [switch]$CheckOnly,
        [switch]$BackupBeforeUpdate
    )
    
    Write-Log "MANAGE" "Starting project update" "INFO"
    
    if ($BackupBeforeUpdate) {
        try {
            $backupPath = Backup-Project
            Write-Log "MANAGE" "Pre-update backup created at: $backupPath" "INFO"
        }
        catch {
            Write-Log "MANAGE" "Pre-update backup failed: $_" "ERROR"
            return $false
        }
    }
    
    $updates = Update-Dependencies -CheckOnly:$CheckOnly
    
    if ($updates.frontend.Count -eq 0 -and $updates.backend.Count -eq 0) {
        Write-Log "MANAGE" "All dependencies are up to date" "INFO"
        return $true
    }
    
    Write-Host "`nAvailable Updates:" -ForegroundColor Cyan
    
    if ($updates.frontend.Count -gt 0) {
        Write-Host "`nFrontend Updates:" -ForegroundColor Yellow
        foreach ($update in $updates.frontend) {
            Write-Host "$($update.name): $($update.current) -> $($update.latest)"
        }
    }
    
    if ($updates.backend.Count -gt 0) {
        Write-Host "`nBackend Updates:" -ForegroundColor Yellow
        foreach ($update in $updates.backend) {
            Write-Host "$($update.name): $($update.current) -> $($update.latest)"
        }
    }
    
    return $true
} 