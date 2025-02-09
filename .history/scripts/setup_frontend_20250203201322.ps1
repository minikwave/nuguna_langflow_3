Write-Host "Setting up frontend..."

# 1. 프론트엔드 디렉토리 생성
if (-not (Test-Path "frontend")) {
    New-Item -ItemType Directory -Path "frontend"
}

Push-Location frontend

# 2. package.json 생성
$package_json = @"
{
  "name": "text-to-sql-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@material-ui/core": "^4.12.4",
    "@material-ui/icons": "^4.11.3",
    "axios": "^0.24.0",
    "react": "^17.0.2",
    "react-dom": "^17.0.2",
    "react-router-dom": "^6.2.1",
    "react-scripts": "5.0.0"
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

# 3. 기본 소스 파일 생성
New-Item -ItemType Directory -Path "src"
$index_js = @"
import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById('root')
);
"@
Set-Content -Path "src/index.js" -Value $index_js

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

# 4. 의존성 설치 및 빌드
npm install
npm run build

Pop-Location 