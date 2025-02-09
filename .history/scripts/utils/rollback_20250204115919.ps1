. .\scripts\utils\logging.ps1
. .\scripts\utils\docker.ps1
. .\scripts\utils\port_management.ps1

# 전역 변수 정의
$script:SERVICE_PORTS = @{
    'frontend' = 3000
    'backend' = 5000
    'database' = 5433
    'redis' = 6379
    'langflow' = 7860
}

function Get-ComponentState {
    param (
        [Parameter(Mandatory=$true)]
        [string]$component
    )
    
    try {
        # 컴포넌트 상태 저장
        $state = @{
            'docker' = @{
                'containers' = docker ps -a --format "{{.Names}}"
                'networks' = docker network ls --format "{{.Name}}"
                'volumes' = docker volume ls --format "{{.Name}}"
            }
            'ports' = @{}
            'processes' = @{}
            'environment' = @{}
        }

        # 포트 상태 저장
        $script:SERVICE_PORTS.GetEnumerator() | ForEach-Object {
            $state.ports[$_.Key] = Test-PortInUse -Port $_.Value
        }

        # 환경 변수 상태 저장
        $state.environment = @{
            'PYTHONPATH' = $env:PYTHONPATH
            'PATH' = $env:PATH
            'NODE_ENV' = $env:NODE_ENV
        }

        # 프로세스 상태 저장 (Windows 특화)
        Get-Process | Where-Object {
            $_.ProcessName -match "(node|python|postgres|redis|langflow)"
        } | ForEach-Object {
            $state.processes[$_.ProcessName] = @{
                'Id' = $_.Id
                'Path' = $_.Path
                'StartTime' = $_.StartTime
            }
        }

        return $state
    }
    catch {
        Write-Log "STATE" "Failed to get component state: $_" "ERROR"
        return $null
    }
}

function Start-ComponentWithRollback {
    param (
        [Parameter(Mandatory=$true)]
        [string]$component,
        [Parameter(Mandatory=$true)]
        [scriptblock]$action,
        [Parameter(Mandatory=$true)]
        [scriptblock]$rollback
    )
    
    $oldState = Get-ComponentState $component
    Write-Log "ROLLBACK" "Saved state for $component" "INFO"
    
    try {
        & $action
        Write-Log "ROLLBACK" "Action completed successfully for $component" "INFO"
        return $true
    }
    catch {
        Write-Log "ROLLBACK" "Error in $component: $_" "ERROR"
        if ($oldState) {
            Write-Log "ROLLBACK" "Rolling back $component..." "WARN"
            try {
                # 롤백 실행
                & $rollback
                
                # 롤백 후 상태 검증
                $newState = Get-ComponentState $component
                $differences = Compare-ComponentState $oldState $newState
                
                if ($differences) {
                    Write-Log "ROLLBACK" "Rollback verification failed: $differences" "WARN"
                } else {
                    Write-Log "ROLLBACK" "Rollback completed successfully" "INFO"
                }
            }
            catch {
                Write-Log "ROLLBACK" "Rollback failed: $_" "ERROR"
                throw [ProjectError]::new(
                    "Rollback failed for $component",
                    $component,
                    "rollback"
                )
            }
        }
        return $false
    }
}

function Compare-ComponentState {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$oldState,
        [Parameter(Mandatory=$true)]
        [hashtable]$newState
    )
    
    $differences = @()
    
    # Docker 상태 비교
    foreach ($key in @('containers', 'networks', 'volumes')) {
        $diff = Compare-Object $oldState.docker[$key] $newState.docker[$key]
        if ($diff) {
            $differences += "Docker $key state mismatch"
        }
    }
    
    # 포트 상태 비교
    foreach ($port in $oldState.ports.Keys) {
        if ($oldState.ports[$port] -ne $newState.ports[$port]) {
            $differences += "Port $port state mismatch"
        }
    }
    
    # 프로세스 상태 비교
    foreach ($proc in $oldState.processes.Keys) {
        if ($oldState.processes[$proc] -ne $newState.processes[$proc]) {
            $differences += "Process $proc state mismatch"
        }
    }
    
    return $differences
} 