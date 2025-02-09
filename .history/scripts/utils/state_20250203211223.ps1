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