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

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Operation,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$Action,
        
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5
    )
    
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            & $Action
            $success = $true
        }
        catch {
            $retryCount++
            Write-Log "RETRY" "Operation '$Operation' failed (Attempt $retryCount/$MaxRetries): $_" "WARN"
            
            if ($retryCount -lt $MaxRetries) {
                Start-Sleep -Seconds ($DelaySeconds * $retryCount)
            }
            else {
                Write-Log "ERROR" "Operation '$Operation' failed after $MaxRetries attempts" "ERROR"
                throw
            }
        }
    }
}

function Restart-FrontendService {
    Write-Log "RECOVERY" "Attempting to restart frontend service" "INFO"
    Stop-Process -Name "node" -ErrorAction SilentlyContinue
    Start-Process powershell -ArgumentList "-NoExit -File scripts\start_frontend.ps1"
}

function Restart-BackendService {
    Write-Log "RECOVERY" "Attempting to restart backend service" "INFO"
    Stop-Process -Name "python" -ErrorAction SilentlyContinue
    Start-Process powershell -ArgumentList "-NoExit -File scripts\start_backend.ps1"
}

function Handle-DockerError {
    param (
        [string]$errorMessage
    )
    
    if ($errorMessage -match "pull access denied") {
        Write-Log "DOCKER" "Image pull failed. Checking alternative repositories..." "WARN"
        return $false
    }
    
    if ($errorMessage -match "context canceled") {
        Write-Log "DOCKER" "Operation timed out. Retrying..." "WARN"
        Start-Sleep -Seconds 5
        return $true
    }
    
    Write-Log "DOCKER" "Unhandled error: $errorMessage" "ERROR"
    return $false
} 