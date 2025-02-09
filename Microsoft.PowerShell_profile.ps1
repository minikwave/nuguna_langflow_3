# 환경변수 설정 방식 수정
$envPaths = @(
    $env:PATH
    "C:\Program Files\PostgreSQL\*\bin"
    "C:\Program Files (x86)\Nmap"
    "C:\Program Files\Docker\Docker\resources\bin"
    # ... 기타 필요한 경로들
)

$env:PATH = $envPaths -join ";" 