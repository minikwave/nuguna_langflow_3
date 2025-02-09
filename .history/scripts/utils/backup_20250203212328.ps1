. .\scripts\utils\logging.ps1

function Backup-Project {
    param (
        [string]$backupDir = "backups"
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $backupDir $timestamp
    
    try {
        # 백업 디렉토리 생성
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        
        # 데이터베이스 백업
        $dbBackupPath = Join-Path $backupPath "database"
        New-Item -ItemType Directory -Path $dbBackupPath -Force | Out-Null
        $env:PGPASSWORD = $env:DB_PASSWORD
        pg_dump -h localhost -p $env:DB_PORT -U $env:DB_USER -F c -b -v -f "$dbBackupPath\db.backup" $env:DB_NAME
        
        # 환경 설정 백업
        Copy-Item ".env" -Destination $backupPath
        Copy-Item "docker-compose.yml" -Destination $backupPath
        
        # 프로젝트 상태 백업
        if (Test-Path ".state") {
            Copy-Item ".state" -Destination $backupPath
        }
        
        Write-Log "BACKUP" "Project backup completed successfully: $backupPath" "INFO"
        return $backupPath
    }
    catch {
        Write-Log "BACKUP" "Backup failed: $_" "ERROR"
        throw
    }
}

function Restore-Project {
    param (
        [Parameter(Mandatory=$true)]
        [string]$backupPath
    )
    
    try {
        # 서비스 중지
        Write-Log "RESTORE" "Stopping services" "INFO"
        docker-compose down
        
        # 데이터베이스 복구
        $dbBackupPath = Join-Path $backupPath "database\db.backup"
        if (Test-Path $dbBackupPath) {
            $env:PGPASSWORD = $env:DB_PASSWORD
            pg_restore -h localhost -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -c -v $dbBackupPath
        }
        
        # 환경 설정 복구
        Copy-Item (Join-Path $backupPath ".env") -Destination "." -Force
        Copy-Item (Join-Path $backupPath "docker-compose.yml") -Destination "." -Force
        
        # 프로젝트 상태 복구
        $statePath = Join-Path $backupPath ".state"
        if (Test-Path $statePath) {
            Copy-Item $statePath -Destination "." -Force
        }
        
        # 서비스 재시작
        docker-compose up -d
        
        Write-Log "RESTORE" "Project restored successfully from: $backupPath" "INFO"
        return $true
    }
    catch {
        Write-Log "RESTORE" "Restore failed: $_" "ERROR"
        throw
    }
} 