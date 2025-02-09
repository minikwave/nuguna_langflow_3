# 롤백 기능
function Start-ComponentWithRollback {
    param (
        [string]$component,
        [scriptblock]$action,
        [scriptblock]$rollback
    )
    
    $oldState = Get-ComponentState $component
    
    try {
        & $action
        return $true
    }
    catch {
        Write-Host "Error in $component: $_"
        if ($oldState) {
            Write-Host "Rolling back $component..."
            try {
                & $rollback
            }
            catch {
                Write-Host "Rollback failed: $_"
            }
        }
        return $false
    }
} 