. .\scripts\utils\logging.ps1

# 컴포넌트 상태 관리
function Get-ComponentState {
    param (
        [string]$component
    )
    
    $statePath = ".\.state\$component.json"
    if (Test-Path $statePath) {
        return Get-Content $statePath | ConvertFrom-Json
    }
    return $null
}

function Set-ComponentState {
    param (
        [string]$component,
        [PSCustomObject]$state
    )
    
    if (-not (Test-Path ".\.state")) {
        New-Item -ItemType Directory -Path ".\.state"
    }
    $state | ConvertTo-Json | Set-Content ".\.state\$component.json"
}

function Test-NeedsReset {
    param (
        [string]$component,
        [string]$version
    )
    
    $state = Get-ComponentState $component
    return (-not $state) -or ($state.version -ne $version)
}

function Get-ProjectState {
    if (-not (Test-Path ".state")) {
        return @{
            "components" = @{}
            "lastInit" = $null
            "environment" = "development"
        }
    }
    
    $state = Get-Content ".state" | ConvertFrom-Json
    return $state
}

function Set-ProjectState {
    param (
        [hashtable]$state
    )
    
    $state | ConvertTo-Json | Set-Content ".state"
}

function Update-ComponentState {
    param (
        [string]$component,
        [string]$version,
        [hashtable]$metadata
    )
    
    $state = Get-ProjectState
    if (-not $state.components.ContainsKey($component)) {
        $state.components[$component] = @{}
    }
    
    $state.components[$component] = @{
        "version" = $version
        "lastUpdate" = Get-Date -Format "o"
        "metadata" = $metadata
    }
    
    Set-ProjectState $state
}

function Test-ComponentNeedsUpdate {
    param (
        [string]$component,
        [string]$targetVersion
    )
    
    $state = Get-ProjectState
    if (-not $state.components.ContainsKey($component)) {
        return $true
    }
    
    $currentVersion = $state.components[$component].version
    return $currentVersion -ne $targetVersion
} 