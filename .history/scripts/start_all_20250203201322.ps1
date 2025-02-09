# 1. DB 마이그레이션
.\scripts\setup_db.ps1

# 2. 프론트엔드 설정
.\scripts\setup_frontend.ps1

# 3. 백엔드 시작 (새 창에서)
Start-Process powershell -ArgumentList "-NoExit -File scripts\start_backend.ps1"

# 4. 프론트엔드 시작 (새 창에서)
Start-Process powershell -ArgumentList "-NoExit -File scripts\start_frontend.ps1"

# 5. Langflow 초기화
.\scripts\init_langflow.ps1 