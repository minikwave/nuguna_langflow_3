. .\scripts\utils\logging.ps1
. .\scripts\frontend\docker_setup.ps1
. .\scripts\frontend\dev_setup.ps1
. .\scripts\frontend\structure_setup.ps1

function Initialize-FrontendComplete {
    Write-Log "FRONTEND" "Starting complete frontend initialization" "INFO"
    
    try {
        # 기본 설정
        Initialize-Frontend
        
        # Docker 환경 설정
        Initialize-FrontendDocker
        
        # 개발 환경 설정
        Initialize-FrontendDev
        
        # 프로젝트 구조 설정
        Initialize-FrontendStructure
        
        Write-Log "FRONTEND" "Frontend initialization completed successfully" "INFO"
        return $true
    }
    catch {
        Write-Log "FRONTEND" "Frontend initialization failed: $_" "ERROR"
        return $false
    }
} 