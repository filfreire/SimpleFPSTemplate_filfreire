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
    Write-Host "`n[1/4] Building project..." -ForegroundColor Green
    try {
        & "$ProjectPath\scripts\build-local.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed. Please fix build errors before continuing."
            exit 1
        }
        Write-Host "Build completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to run build script: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "[1/4] Skipping build step" -ForegroundColor Yellow
}

# Step 2: Package for training (optional)
if (-not $SkipPackage) {
    Write-Host "`n[2/4] Creating training build..." -ForegroundColor Green
    try {
        & "$ProjectPath\scripts\package-training.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Packaging failed. Please check the packaging logs."
            exit 1
        }
        Write-Host "Training build created successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to run packaging script: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "[2/4] Skipping packaging step" -ForegroundColor Yellow
}

# Step 3: Provide configuration guidance
Write-Host "`n[3/4] Configuration Check" -ForegroundColor Green
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

$confirmation = Read-Host "`nHave you completed all the above configuration? (y/N)"
if ($confirmation -notmatch '^[Yy]$') {
    Write-Host "`nPlease complete the configuration in Unreal Editor first." -ForegroundColor Yellow
    Write-Host "Refer to docs/headless-training-setup.md for detailed instructions." -ForegroundColor Cyan
    $ConfigComplete = $false
}

# Step 4: Ready to train
Write-Host "`n[4/4] Training Setup Complete" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

if ($ConfigComplete) {
    Write-Host "Setup completed successfully!" -ForegroundColor Green
    Write-Host "`nYou can now start headless training with:" -ForegroundColor Cyan
    Write-Host "  .\scripts\run-training-headless.ps1" -ForegroundColor White
    
    Write-Host "`nOptional monitoring commands:" -ForegroundColor Cyan
    Write-Host "  # Start TensorBoard (in another terminal)" -ForegroundColor Gray
    Write-Host "  .\scripts\run-tensorboard.ps1" -ForegroundColor White
    Write-Host "`n  # Monitor training logs (in another terminal)" -ForegroundColor Gray
    Write-Host "  .\scripts\tail-training-logs.ps1" -ForegroundColor White
    Write-Host "  # Or manually:" -ForegroundColor Gray
    Write-Host "  cd TrainingBuild\Windows\FPSGame\Binaries\Win64" -ForegroundColor White
    Write-Host "  Get-Content -Path fpscharacter_training.log -Wait" -ForegroundColor White
    
    $startTraining = Read-Host "`nWould you like to start training now? (y/N)"
    if ($startTraining -match '^[Yy]$') {
        Write-Host "`nStarting headless training..." -ForegroundColor Green
        & "$ProjectPath\scripts\run-training-headless.ps1"
    }
} else {
    Write-Host "Configuration incomplete. Please complete the setup first." -ForegroundColor Yellow
}

Write-Host "`nFor detailed information, see:" -ForegroundColor Cyan
Write-Host "  - docs/headless-training-setup.md" -ForegroundColor White
Write-Host "  - docs/learning-agents-setup.md" -ForegroundColor White
