. .\scripts\utils\logging.ps1

function Get-ServiceStatus {
    $services = @{
        "frontend" = @{
            port = 3000
            process = "node"
            url = "http://localhost:3000/health"
        }
        "backend" = @{
            port = 5000
            process = "python"
            url = "http://localhost:5000/health"
        }
        "database" = @{
            port = $env:DB_PORT
            process = "postgres"
        }
        "langflow" = @{
            port = 7860
            url = "http://localhost:7860/health"
        }
    }
    
    $status = @{}
    
    foreach ($service in $services.Keys) {
        $serviceInfo = $services[$service]
        $status[$service] = @{
            running = $false
            port_available = $false
            health = "unknown"
            details = ""
        }
        
        # 프로세스 체크
        if (Get-Process -Name $serviceInfo.process -ErrorAction SilentlyContinue) {
            $status[$service].running = $true
        }
        
        # 포트 체크
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect("localhost", $serviceInfo.port)
            $status[$service].port_available = $true
            $tcp.Close()
        } catch {}
        
        # 헬스 체크
        if ($serviceInfo.ContainsKey("url")) {
            try {
                $response = Invoke-WebRequest -Uri $serviceInfo.url -Method GET -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    $status[$service].health = "healthy"
                }
            } catch {
                $status[$service].health = "unhealthy"
                $status[$service].details = $_.Exception.Message
            }
        }
    }
    
    return $status
}

function Show-ServiceStatus {
    $status = Get-ServiceStatus
    Write-Host "`nService Status:" -ForegroundColor Cyan
    
    foreach ($service in $status.Keys) {
        Write-Host "`n$($service.ToUpper()):" -ForegroundColor Yellow
        Write-Host "Port Available: $($status[$service].port_available)"
        Write-Host "Health: $($status[$service].health)"
        if ($status[$service].details) {
            Write-Host "Details: $($status[$service].details)"
        }
    }
}

# 실행
Show-ServiceStatus 