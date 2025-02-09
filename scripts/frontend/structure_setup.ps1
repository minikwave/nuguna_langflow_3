. .\scripts\utils\logging.ps1

function Initialize-FrontendStructure {
    Write-Log "FRONTEND" "Setting up frontend project structure" "INFO"
    
    Push-Location frontend
    
    # 기본 디렉토리 구조 생성
    $directories = @(
        "src/components",
        "src/pages",
        "src/services",
        "src/hooks",
        "src/utils",
        "src/assets",
        "src/styles",
        "src/context",
        "src/types"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force
            Write-Log "FRONTEND" "Created directory: $dir" "INFO"
        }
    }
    
    # 기본 컴포넌트 템플릿 생성
    $component_template = @"
import React from 'react';
import './styles.css';

interface Props {
    // Define props here
}

export const Component: React.FC<Props> = (props) => {
    return (
        <div>
            {/* Component content */}
        </div>
    );
};
"@
    Set-Content -Path "src/components/Template.tsx" -Value $component_template
    
    # API 서비스 설정
    $api_service = @"
import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL;

export const api = axios.create({
    baseURL: API_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});
"@
    Set-Content -Path "src/services/api.ts" -Value $api_service
    
    Pop-Location
} 