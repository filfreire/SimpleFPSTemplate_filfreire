# Complete Headless Training Setup for FPSGame
# This script provides a complete workflow to set up headless training
# Usage: .\scripts\setup-headless-training.ps1 [-SkipBuild] [-SkipPackage]

param(
    [switch]$SkipBuild = $false,
    [switch]$SkipPackage = $false,
    [string]$ProjectPath = (Get-Location).Path
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "FPSGAME HEADLESS TRAINING SETUP" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "This script will guide you through setting up headless training for FPSGame." -ForegroundColor Yellow
Write-Host "Please ensure you have configured your FPSCharacterManager blueprint first!" -ForegroundColor Yellow

# Step 1: Build the project (optional)
if (-not $SkipBuild) {
    Write-Host "`n[1/6] Building project..." -ForegroundColor Green
    & "$ProjectPath\scripts\build-local.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed. Please fix build errors before continuing."
        exit 1
    }
    Write-Host "Build completed successfully" -ForegroundColor Green
    Write-Host "Learning Agents dependencies should now be installed automatically" -ForegroundColor Cyan
} else {
    Write-Host "[1/6] Skipping build step" -ForegroundColor Yellow
    Write-Host "Note: Learning Agents dependencies may not be installed" -ForegroundColor Yellow
}

# Step 2: Install dependencies (Learning Agents + TensorBoard)
Write-Host "`n[2/6] Installing dependencies..." -ForegroundColor Green
& "$ProjectPath\scripts\setup.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Dependency installation failed. Please check the installation logs."
    exit 1
}
Write-Host "Dependencies installed successfully" -ForegroundColor Green

# Step 3: Package for training (optional)
if (-not $SkipPackage) {
    Write-Host "`n[3/6] Creating training build..." -ForegroundColor Green
    & "$ProjectPath\scripts\package-training.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Packaging failed. Please check the packaging logs."
        exit 1
    }
    Write-Host "Training build created successfully" -ForegroundColor Green
} else {
    Write-Host "[3/6] Skipping packaging step" -ForegroundColor Yellow
}

# Step 4: Verify TensorBoard availability
Write-Host "`n[4/6] Verifying TensorBoard availability..." -ForegroundColor Green

# Determine Unreal Engine path
$hostname = [System.Net.Dns]::GetHostName()
if ($hostname -match "^filfreire01$") {
    $UnrealPath = "C:\unreal\UE_5.6"
} elseif ($hostname -match "^filfreire02$") {
    $UnrealPath = "D:\unreal\UE_5.6"
} elseif ($hostname -match "^desktop-doap6m9$") {
    $UnrealPath = "E:\unreal\UE_5.6"
} elseif ($hostname -match "^unreal-") {
    $UnrealPath = "C:\unreal\UE_5.6"
} else {
    $UnrealPath = "D:\unreal\UE_5.6"
}

$UnrealPythonExe = Join-Path $UnrealPath "Engine\Binaries\ThirdParty\Python3\Win64\python.exe"

if (Test-Path $UnrealPythonExe) {
    Write-Host "✓ Unreal Engine Python found at: $UnrealPythonExe" -ForegroundColor Green
    
    # Check if TensorBoard is installed
    $pipOutput = & $UnrealPythonExe -m pip list 2>&1 | Out-String
    if ($pipOutput -match "tensorboard") {
        Write-Host "✓ TensorBoard is installed in Unreal Engine's Python" -ForegroundColor Green
    } else {
        Write-Host "⚠ TensorBoard not found in Unreal Engine's Python" -ForegroundColor Yellow
        Write-Host "Run setup.ps1 to install it" -ForegroundColor Gray
    }
} else {
    Write-Host "⚠ Unreal Engine Python not found at: $UnrealPythonExe" -ForegroundColor Yellow
    Write-Host "Please verify your Unreal Engine installation" -ForegroundColor Gray
}

# Step 5: Provide configuration guidance
Write-Host "`n[5/6] Configuration Check" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

$ConfigComplete = $true

Write-Host "Please verify the following configuration in Unreal Editor:" -ForegroundColor Yellow

Write-Host "`nFPSCharacterManager Configuration:" -ForegroundColor Cyan
Write-Host "  - Run Mode: Any mode (will auto-force to Training in headless)" -ForegroundColor White
Write-Host "  - All four neural networks assigned:" -ForegroundColor White
Write-Host "     - Encoder Neural Network" -ForegroundColor Gray
Write-Host "     - Policy Neural Network" -ForegroundColor Gray
Write-Host "     - Decoder Neural Network" -ForegroundColor Gray
Write-Host "     - Critic Neural Network" -ForegroundColor Gray
Write-Host "  - Target Actor reference set" -ForegroundColor White

Write-Host "`nTrainer Training Settings:" -ForegroundColor Cyan
Write-Host "  - Use Tensorboard = True" -ForegroundColor White
Write-Host "  - Save Snapshots = True" -ForegroundColor White

Write-Host "`nTrainer Path Settings:" -ForegroundColor Cyan
Write-Host "  - Non Editor Engine Relative Path configured" -ForegroundColor White
Write-Host "  - Non Editor Intermediate Relative Path configured" -ForegroundColor White
Write-Host "     (Check the package-training.ps1 output for these paths)" -ForegroundColor Gray

Write-Host "`nTraining Map (P_LearningAgentsTrial):" -ForegroundColor Cyan
Write-Host "  - FPSCharacter instances placed" -ForegroundColor White
Write-Host "  - FPSTargetActor placed" -ForegroundColor White
Write-Host "  - FPSCharacterManager placed and configured" -ForegroundColor White

Write-Host "`nPlease ensure you have completed all the above configuration in Unreal Editor." -ForegroundColor Yellow
Write-Host "Refer to docs/headless-training-setup.md for detailed instructions." -ForegroundColor Cyan
$ConfigComplete = $true

# Step 6: Ready to train
Write-Host "`n[6/6] Training Setup Complete" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

if ($ConfigComplete) {
    Write-Host "Setup completed successfully!" -ForegroundColor Green
    Write-Host "`nYou can now start headless training with:" -ForegroundColor Cyan
    Write-Host "  .\scripts\run-training-headless.ps1" -ForegroundColor White
    
    Write-Host "`nOptional monitoring commands:" -ForegroundColor Cyan
    Write-Host "  # Start TensorBoard (in another terminal)" -ForegroundColor Gray
    Write-Host "  .\scripts\run-tensorboard.ps1" -ForegroundColor White
    Write-Host "  # TensorBoard will be available at: http://localhost:6006" -ForegroundColor Gray
    Write-Host "`n  # Monitor training logs (in another terminal)" -ForegroundColor Gray
    Write-Host "  .\scripts\tail-training-logs.ps1" -ForegroundColor White
    Write-Host "  # Or manually:" -ForegroundColor Gray
    Write-Host "  cd TrainingBuild\Windows\FPSGame\Binaries\Win64" -ForegroundColor White
    Write-Host "  Get-Content -Path fpscharacter_training.log -Wait" -ForegroundColor White
    
    Write-Host "`nReady to start training when you are!" -ForegroundColor Green
} else {
    Write-Host "Configuration incomplete. Please complete the setup first." -ForegroundColor Yellow
}

Write-Host "`nFor detailed information, see:" -ForegroundColor Cyan
Write-Host "  - docs/headless-training-setup.md" -ForegroundColor White
Write-Host "  - docs/learning-agents-setup.md" -ForegroundColor White
