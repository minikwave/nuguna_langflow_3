# 유틸리티 스크립트 로드
. .\scripts\utils\state.ps1
. .\scripts\utils\rollback.ps1
. .\scripts\utils\logging.ps1

Write-Log "MAIN" "Starting reset process" "INFO"

# 컴포넌트 버전 정의
$versions = @{
    "postgresql" = "13.0"
    "frontend" = "1.0"
    "backend" = "1.0"
    "langflow" = "1.0"
}

# 각 컴포넌트 리셋 전 상태 체크
foreach ($component in $versions.Keys) {
    if (-not (Test-NeedsReset $component $versions[$component])) {
        Write-Log $component "Skip reset - version up to date" "INFO"
        continue
    }
    
    Write-Log $component "Starting reset" "INFO"
    $success = Start-ComponentWithRollback $component {
        switch ($component) {
            "postgresql" { 
                .\scripts\install_postgres.ps1
                Set-ComponentState "postgresql" @{version=$versions.postgresql; lastReset=Get-Date}
            }
            "frontend" { 
                .\scripts\reset_frontend.ps1
                Set-ComponentState "frontend" @{version=$versions.frontend; lastReset=Get-Date}
            }
            "backend" { 
                .\scripts\reset_backend.ps1
                Set-ComponentState "backend" @{version=$versions.backend; lastReset=Get-Date}
            }
            "langflow" { 
                .\scripts\reset_langflow.ps1
                Set-ComponentState "langflow" @{version=$versions.langflow; lastReset=Get-Date}
            }
        }
    } {
        # 롤백 로직
        Write-Log $component "Rolling back changes" "WARN"
        switch ($component) {
            "postgresql" { Stop-Service postgresql-x64-13 }
            "frontend" { Stop-Process -Name "node" -ErrorAction SilentlyContinue }
            "backend" { Stop-Process -Name "python" -ErrorAction SilentlyContinue }
            "langflow" { Stop-Process -Name "langflow" -ErrorAction SilentlyContinue }
        }
    }
    
    if (-not $success) {
        Write-Log $component "Reset failed" "ERROR"
        exit 1
    }
}

Write-Log "MAIN" "All components have been reset successfully" "INFO" 