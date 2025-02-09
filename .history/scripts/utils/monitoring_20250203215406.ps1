. .\scripts\utils\logging.ps1

function Get-ServiceStatus {
    Write-Host "Checking service status..." -ForegroundColor Yellow
    
    $services = @{
        "frontend" = @{
            port = 3000
            container = "text-to-sql-frontend"
            url = "http://localhost:3000/health"
        }
        "backend" = @{
            port = 5000
            container = "text-to-sql-backend"
            url = "http://localhost:5000/health"
        }
        "database" = @{
            port = $env:DB_PORT
            container = "text-to-sql-db"
        }
        "redis" = @{
            port = 6379
            container = "text-to-sql-redis"
        }
        "langflow" = @{
            port = 7860
            container = "text-to-sql-langflow"
            url = "http://localhost:7860/health"
        }
    }
    
    $status = @{}
    
    foreach ($service in $services.Keys) {
        Write-Host "`nChecking $service..." -ForegroundColor Cyan
        $status[$service] = @{
            running = $false
            port_available = $false
            health = "unknown"
            container_status = "not found"
            logs = ""
        }
        
        # 컨테이너 상태 확인
        $containerInfo = docker inspect $services[$service].container 2>$null | ConvertFrom-Json
        if ($containerInfo) {
            $status[$service].running = $containerInfo.State.Running
            $status[$service].container_status = $containerInfo.State.Status
            
            # 컨테이너 로그
            $status[$service].logs = docker logs --tail 5 $services[$service].container 2>&1
        }
        
        # 포트 확인
        try {
            $conn = New-Object System.Net.Sockets.TcpClient
            $conn.Connect("localhost", $services[$service].port)
            $status[$service].port_available = $true
            $conn.Close()
        }
        catch {
            $status[$service].port_available = $false
        }
        
        # 헬스 체크
        if ($services[$service].url) {
            try {
                $response = Invoke-WebRequest $services[$service].url -UseBasicParsing
                $status[$service].health = if ($response.StatusCode -eq 200) { "healthy" } else { "unhealthy" }
            }
            catch {
                $status[$service].health = "unreachable"
            }
        }
    }
    
    return $status
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