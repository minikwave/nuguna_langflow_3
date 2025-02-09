Write-Host "Resetting frontend..."

# 1. Clean
Write-Host "Cleaning frontend..."
Push-Location frontend
if (Test-Path "build") {
    Remove-Item "build" -Recurse -Force
    Write-Host "Cleaned build directory"
}
if (Test-Path "node_modules") {
    Remove-Item "node_modules" -Recurse -Force
    Write-Host "Cleaned node_modules"
}
Pop-Location

# 2. Setup
Write-Host "Setting up frontend..."
Push-Location frontend

# src 디렉토리 생성
if (-not (Test-Path "src")) {
    New-Item -ItemType Directory -Path "src"
}

# index.js 생성
$index_js = @"
import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';
import './index.css';

ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById('root')
);
"@
Set-Content -Path "src/index.js" -Value $index_js

# index.css 생성
$index_css = @"
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
"@
Set-Content -Path "src/index.css" -Value $index_css

# App.js 생성
$app_js = @"
import React from 'react';

function App() {
  return (
    <div>
      <h1>Text to SQL Application</h1>
    </div>
  );
}

export default App;
"@
Set-Content -Path "src/App.js" -Value $app_js

# package.json에 필요한 의존성 추가
$package_json = @"
{
  "name": "text-to-sql-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@mui/material": "^5.0.0",
    "@mui/icons-material": "^5.0.0",
    "@reduxjs/toolkit": "^1.9.5",
    "axios": "^1.4.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-redux": "^8.1.1",
    "react-router-dom": "^6.14.1",
    "react-scripts": "5.0.1",
    "typescript": "^4.9.5",
    "web-vitals": "^2.1.4"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  }
}
"@
Set-Content -Path "package.json" -Value $package_json

# node_modules 삭제 후 재설치
Remove-Item -Path "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "package-lock.json" -Force -ErrorAction SilentlyContinue

# npm 캐시 정리 및 재설치
npm cache clean --force
npm install --legacy-peer-deps

# 의존성 설치
Write-Log "FRONTEND" "Installing dependencies" "INFO"
npm install --save @reduxjs/toolkit @types/react-redux typescript @types/node @types/react @types/react-dom
npm install --save-dev @typescript-eslint/eslint-plugin @typescript-eslint/parser

# TypeScript 설정 파일이 없다면 생성
if (-not (Test-Path "tsconfig.json")) {
    Write-Log "FRONTEND" "Creating TypeScript configuration" "INFO"
    npx tsc --init --jsx react-jsx
}

# package-lock.json 재생성
Remove-Item -Path "package-lock.json" -ErrorAction SilentlyContinue
npm install

npm run build
Start-Process npm -ArgumentList "start" -NoNewWindow

Pop-Location 