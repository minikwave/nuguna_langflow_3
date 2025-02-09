. .\scripts\utils\logging.ps1

function Test-PortInUse {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Port
    )
    
    try {
        $endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Loopback, $Port)
        $socket = New-Object System.Net.Sockets.TcpListener $endpoint
        $socket.Start()
        $socket.Stop()
        return $false
    }
    catch {
        return $true
    }
}

function Get-ProcessUsingPort {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Port
    )
    
    $processList = netstat -ano | Select-String ":$Port\s"
    if ($processList) {
        $processId = $processList.Line.Split(' ')[-1]
        return Get-Process -Id $processId
    }
    return $null
}

function Clear-PortIfInUse {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Port,
        [string]$ServiceName
    )
    
    if (Test-PortInUse -Port $Port) {
        Write-Log "PORT" "Port $Port is in use by another process" "WARN"
        $process = Get-ProcessUsingPort -Port $Port
        
        if ($process) {
            Write-Log "PORT" "Attempting to stop process using port $Port (PID: $($process.Id))" "INFO"
            try {
                Stop-Process -Id $process.Id -Force
                Start-Sleep -Seconds 2
                Write-Log "PORT" "Successfully cleared port $Port" "INFO"
            }
            catch {
                Write-Log "PORT" "Failed to stop process on port $Port: $_" "ERROR"
                throw
            }
        }
    }
} 