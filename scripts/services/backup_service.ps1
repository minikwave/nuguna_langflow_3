. .\scripts\utils\logging.ps1
. .\scripts\utils\backup.ps1

$backupInterval = 24 # 시간 단위

Write-Log "BACKUP" "Starting backup service (Interval: $backupInterval hours)" "INFO"

while ($true) {
    try {
        $backupPath = Backup-Project
        Write-Log "BACKUP" "Backup created at: $backupPath" "INFO"
        
        # 오래된 백업 정리 (7일 이상)
        Get-ChildItem "backups" | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-7)
        } | ForEach-Object {
            Remove-Item $_.FullName -Recurse -Force
            Write-Log "BACKUP" "Removed old backup: $($_.Name)" "INFO"
        }
    }
    catch {
        Write-Log "BACKUP" "Backup failed: $_" "ERROR"
    }
    
    Start-Sleep -Seconds ($backupInterval * 3600)
} 