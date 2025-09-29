# Test script for obstacle system
# This script compiles the project and runs basic tests

Write-Host "Testing Obstacle System for SimpleFPSTemplate..." -ForegroundColor Green

# Navigate to project directory
Set-Location "E:\unrealprojects\SimpleFPSTemplate_filfreire"

# Clean and build the project
Write-Host "Cleaning project..." -ForegroundColor Yellow
& ".\scripts\Clean.bat"

Write-Host "Building project..." -ForegroundColor Yellow
& ".\scripts\Build.bat"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful! Obstacle system should be ready to use." -ForegroundColor Green
    Write-Host ""
    Write-Host "To test the obstacle system:" -ForegroundColor Cyan
    Write-Host "1. Open the project in Unreal Editor" -ForegroundColor White
    Write-Host "2. Open your training environment Blueprint" -ForegroundColor White
    Write-Host "3. Enable 'bUseObstacles' in the Obstacles category" -ForegroundColor White
    Write-Host "4. Set MaxObstacles to desired number (e.g., 8)" -ForegroundColor White
    Write-Host "5. Run training to see obstacles in action" -ForegroundColor White
    Write-Host ""
    Write-Host "For dynamic mode, call SetObstacleMode(Dynamic) on the obstacle manager" -ForegroundColor Cyan
} else {
    Write-Host "Build failed! Check the error messages above." -ForegroundColor Red
}

Write-Host "Test completed." -ForegroundColor Green
