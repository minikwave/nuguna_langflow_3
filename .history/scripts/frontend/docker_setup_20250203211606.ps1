. .\scripts\utils\logging.ps1

function Initialize-FrontendDocker {
    Write-Log "FRONTEND" "Setting up frontend Docker environment" "INFO"
    
    # nginx.conf 생성
    $nginx_conf = @"
server {
    listen 3000;
    
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files `$uri `$uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:5000;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
    }

    location /langflow {
        proxy_pass http://langflow:7860;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection 'upgrade';
    }
}
"@
    Set-Content -Path "frontend/nginx.conf" -Value $nginx_conf

    # .dockerignore 생성
    $dockerignore = @"
node_modules
build
.dockerignore
Dockerfile
.git
.gitignore
README.md
"@
    Set-Content -Path "frontend/.dockerignore" -Value $dockerignore
} 