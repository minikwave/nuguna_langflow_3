. .\scripts\utils\logging.ps1

function Initialize-FrontendDev {
    Write-Log "FRONTEND" "Setting up frontend development environment" "INFO"
    
    Push-Location frontend
    
    # package.json 스크립트 보강
    $package_json = Get-Content "package.json" | ConvertFrom-Json
    $package_json.scripts | Add-Member -NotePropertyName "lint" -NotePropertyValue "eslint src/**/*.{js,jsx}"
    $package_json.scripts | Add-Member -NotePropertyName "format" -NotePropertyValue "prettier --write src/**/*.{js,jsx,css}"
    $package_json.scripts | Add-Member -NotePropertyName "test:ci" -NotePropertyValue "react-scripts test --watchAll=false"
    $package_json | ConvertTo-Json -Depth 10 | Set-Content "package.json"
    
    # 추가 개발 의존성 설치
    $dev_packages = @(
        "eslint",
        "prettier",
        "@testing-library/react",
        "@testing-library/jest-dom",
        "husky",
        "lint-staged"
    )
    
    foreach ($package in $dev_packages) {
        Write-Log "FRONTEND" "Installing dev dependency: $package" "INFO"
        npm install --save-dev $package
    }
    
    # ESLint 설정
    $eslint_config = @"
{
    "extends": [
        "react-app",
        "react-app/jest"
    ],
    "rules": {
        "no-console": "warn",
        "no-unused-vars": "warn"
    }
}
"@
    Set-Content -Path ".eslintrc.json" -Value $eslint_config
    
    # Prettier 설정
    $prettier_config = @"
{
    "semi": true,
    "singleQuote": true,
    "tabWidth": 2,
    "trailingComma": "es5"
}
"@
    Set-Content -Path ".prettierrc" -Value $prettier_config
    
    Pop-Location
} 