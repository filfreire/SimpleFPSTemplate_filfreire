# Setup pre-commit hooks for simplefpstemplate_filfreire repository
# PowerShell version

Write-Host "🔧 Setting up pre-commit hooks for simplefpstemplate_filfreire..." -ForegroundColor Cyan

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Found Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python is required but not installed. Please install Python 3." -ForegroundColor Red
    exit 1
}

# Check if pip is installed
try {
    $pipVersion = pip --version 2>&1
    Write-Host "✅ Found pip: $pipVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ pip is required but not installed. Please install pip." -ForegroundColor Red
    exit 1
}

# Install pre-commit
Write-Host "📦 Installing pre-commit..." -ForegroundColor Yellow
pip install pre-commit

# Install the pre-commit hooks
Write-Host "🪝 Installing pre-commit hooks..." -ForegroundColor Yellow
pre-commit install

# Run pre-commit on all files to ensure everything is working
Write-Host "🧹 Running pre-commit on all files (this may take a while on first run)..." -ForegroundColor Yellow
try {
    pre-commit run --all-files
    Write-Host "✅ All pre-commit checks passed!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Some pre-commit checks failed. This is normal for the first run." -ForegroundColor Yellow
    Write-Host "💡 You can fix the issues and run 'pre-commit run --all-files' again." -ForegroundColor Blue
}

Write-Host ""
Write-Host "✅ Pre-commit setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Available commands:" -ForegroundColor Cyan
Write-Host "  • Run on all files:     pre-commit run --all-files" -ForegroundColor White
Write-Host "  • Run on staged files:  pre-commit run" -ForegroundColor White
Write-Host "  • Update hooks:         pre-commit autoupdate" -ForegroundColor White
Write-Host "  • Uninstall hooks:      pre-commit uninstall" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Pre-commit will now run automatically on every commit!" -ForegroundColor Green
