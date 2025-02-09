. .\scripts\utils\logging.ps1

function Invoke-DatabaseMigration {
    Write-Log "DATABASE" "Starting database migration" "INFO"
    
    # 데이터베이스 연결 테스트
    try {
        $env:PGPASSWORD = "password"
        $result = & psql -U postgres -p 5434 -d text_to_sql -c "\conninfo"
        if ($LASTEXITCODE -ne 0) {
            Write-Log "DATABASE" "Database connection failed" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "DATABASE" "Database connection error: $_" "ERROR"
        return $false
    }

    # 마이그레이션 실행
    try {
        alembic upgrade head
        Write-Log "DATABASE" "Migration completed successfully" "INFO"
        return $true
    }
    catch {
        Write-Log "DATABASE" "Migration failed: $_" "ERROR"
        return $false
    }
} 