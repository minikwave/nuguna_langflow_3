. .\scripts\utils\logging.ps1

function Test-AdminPrivileges {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Initialize-WindowsEnvironment {
    Write-Log "WINDOWS" "Initializing Windows environment" "INFO"
    
    # 관리자 권한 확인
    if (-not (Test-AdminPrivileges)) {
        Write-Log "WINDOWS" "Administrator privileges required" "ERROR"
        throw "This script requires administrator privileges"
    }
    
    # Windows 기능 확인
    $requiredFeatures = @(
        "Microsoft-Windows-Subsystem-Linux",
        "VirtualMachinePlatform"
    )
    
    foreach ($feature in $requiredFeatures) {
        if (-not (Get-WindowsOptionalFeature -Online -FeatureName $feature).State -eq "Enabled") {
            Write-Log "WINDOWS" "Enabling $feature" "INFO"
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
        }
    }
    
    # 환경 변수 설정
    $envVars = @{
        'PYTHONPATH' = "$PWD;$PWD\src"
        'NODE_ENV' = 'development'
    }
    
    foreach ($var in $envVars.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($var.Key, $var.Value, [EnvironmentVariableTarget]::Process)
        [Environment]::SetEnvironmentVariable($var.Key, $var.Value, [EnvironmentVariableTarget]::User)
    }
    
    # 방화벽 규칙 설정
    $ports = $script:SERVICE_PORTS.Values
    foreach ($port in $ports) {
        $ruleName = "Text-to-SQL-Port-$port"
        if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow
        }
    }
} 