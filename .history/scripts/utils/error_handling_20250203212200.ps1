. .\scripts\utils\logging.ps1

class ProjectError : Exception {
    [string]$Component
    [string]$Operation
    
    ProjectError([string]$message, [string]$component, [string]$operation) : base($message) {
        $this.Component = $component
        $this.Operation = $operation
    }
}

function Invoke-WithRollback {
    param (
        [string]$component,
        [string]$operation,
        [scriptblock]$action,
        [scriptblock]$rollback
    )
    
    $errorActionPreference = "Stop"
    $success = $false
    
    try {
        Write-Log $component "Starting operation: $operation" "INFO"
        & $action
        $success = $true
        Write-Log $component "Operation completed successfully: $operation" "INFO"
    }
    catch {
        Write-Log $component "Operation failed: $operation" "ERROR"
        Write-Log $component $_.Exception.Message "ERROR"
        
        try {
            Write-Log $component "Attempting rollback" "WARN"
            & $rollback
            Write-Log $component "Rollback completed" "INFO"
        }
        catch {
            Write-Log $component "Rollback failed: $_" "ERROR"
            throw [ProjectError]::new(
                "Critical failure - rollback unsuccessful",
                $component,
                $operation
            )
        }
        
        throw [ProjectError]::new(
            $_.Exception.Message,
            $component,
            $operation
        )
    }
    
    return $success
} 