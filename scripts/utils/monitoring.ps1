. .\scripts\utils\logging.ps1

function Get-ServiceStatus {
    $services = @{
        'langflow' = @{port = 7860; container = 'text-to-sql-langflow'}
        'backend' = @{port = 5000; container = 'text-to-sql-backend'}
        'database' = @{port = 5433; container = 'text-to-sql-db'}
        'redis' = @{port = 6379; container = 'text-to-sql-redis'}
        'frontend' = @{port = 3000; container = 'text-to-sql-frontend'}
    }
    
    $results = @{}
    
    foreach ($service in $services.Keys) {
        $status = @{
            container_status = "unknown"
            running = $false
            port_available = $false
            health = "unknown"
        }
        
        # 컨테이너 상태 확인
        $containerInfo = docker ps -a --filter name=$services[$service].container --format "{{.Status}}"
        if ($containerInfo) {
            $status.container_status = $containerInfo
            $status.running = $containerInfo -match "Up"
        }
        
        # 포트 확인
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect("localhost", $services[$service].port)
            $status.port_available = $true
            $tcpClient.Close()
        }
        catch {}
        
        $results[$service] = $status
    }
    
    return $results
}

function Show-ServiceStatus {
    $status = Get-ServiceStatus
    Write-Host "`nDetailed Service Status:" -ForegroundColor Cyan
    
    foreach ($service in $status.Keys) {
        Write-Host "`n$($service.ToUpper()):" -ForegroundColor Yellow
        Write-Host "Container Status: $($status[$service].container_status)"
        Write-Host "Running: $($status[$service].running)"
        Write-Host "Port Available: $($status[$service].port_available)"
        Write-Host "Health: $($status[$service].health)"
        
        Write-Host "`nRecent Logs:" -ForegroundColor Gray
        $status[$service].logs | ForEach-Object {
            Write-Host "  $_" -ForegroundColor DarkGray
        }
    }
}

# 실행
Show-ServiceStatus 