# Batch Training Runner for CoopGameFleep
# This script runs multiple training configurations sequentially
# Usage: .\scripts\run-batch-special.ps1

param(
    [switch]$SkipConservative = $false,
    [switch]$SkipAggressive = $false,
    [switch]$SkipBalanced = $false,
    [switch]$StopOnError = $false
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "COOPGAMEFLEEP BATCH TRAINING RUNNER" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Set the project directory
$ProjectDir = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectDir

Write-Host "Project Directory: $ProjectDir" -ForegroundColor Yellow
Write-Host ""

# Function to run a training configuration
function Invoke-TrainingRun {
    param(
        [string]$RunName,
        [string]$Description,
        [hashtable]$Parameters
    )
    
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "RUN $RunName`: $Description" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Cyan
    
    # Display parameters
    Write-Host "Parameters:" -ForegroundColor White
    foreach ($key in $Parameters.Keys) {
        Write-Host "  $key`: $($Parameters[$key])" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Build the command arguments as a string
    $cmdArgs = @()
    foreach ($key in $Parameters.Keys) {
        # Ensure RandomSeed is passed as integer to avoid type conversion issues
        if ($key -eq "RandomSeed") {
            $cmdArgs += "-$key $([int]$Parameters[$key])"
        } else {
            # Convert decimal separator from comma to dot for proper PowerShell parsing
            $value = $Parameters[$key].ToString()
            if ($value -match '^\d+,\d+$') {
                $value = $value -replace ',', '.'
            }
            $cmdArgs += "-$key $value"
        }
    }
    
    $commandString = ".\scripts\run-training-headless.ps1 " + ($cmdArgs -join ' ')
    
    Write-Host "Executing training run..." -ForegroundColor Green
    Write-Host "Command: $commandString" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Execute the training script using Invoke-Expression to properly parse the command
        Invoke-Expression $commandString
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Run $RunName completed successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Run $RunName failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Run $RunName failed with error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
}

# Define the three training configurations
$ConservativeParams = @{
    TimeoutMinutes = 5
    RandomSeed = 1001
    LearningRatePolicy = 0.00005
    LearningRateCritic = 0.0005
    EpsilonClip = 0.1
    PolicyBatchSize = 512
    CriticBatchSize = 2048
    IterationsPerGather = 16
    DiscountFactor = 0.95
    GaeLambda = 0.9
    ActionEntropyWeight = 0.01
}

$AggressiveParams = @{
    TimeoutMinutes = 5
    RandomSeed = 2002
    LearningRatePolicy = 0.0003
    LearningRateCritic = 0.003
    EpsilonClip = 0.3
    PolicyBatchSize = 2048
    CriticBatchSize = 8192
    IterationsPerGather = 64
    DiscountFactor = 0.995
    GaeLambda = 0.95
    ActionEntropyWeight = 0.0
}

$BalancedParams = @{
    TimeoutMinutes = 5
    RandomSeed = 3003
    LearningRatePolicy = 0.0001
    LearningRateCritic = 0.001
    EpsilonClip = 0.2
    PolicyBatchSize = 1024
    CriticBatchSize = 4096
    IterationsPerGather = 32
    DiscountFactor = 0.99
    GaeLambda = 0.95
    ActionEntropyWeight = 0.005
}

# Track results
$Results = @{}

# Conservative: Low learning rate, small batches
if (-not $SkipConservative) {
    $Results["Conservative"] = Invoke-TrainingRun -RunName "Conservative" -Description "CONSERVATIVE / LOW LEARNING RATE" -Parameters $ConservativeParams
    
    if ($StopOnError -and -not $Results["Conservative"]) {
        Write-Host "Stopping execution due to error in Conservative run (StopOnError flag set)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Skipping Conservative run (SkipConservative flag set)" -ForegroundColor Yellow
    Write-Host ""
}

# Aggressive: High learning rate, large batches
if (-not $SkipAggressive) {
    $Results["Aggressive"] = Invoke-TrainingRun -RunName "Aggressive" -Description "AGGRESSIVE / HIGH LEARNING RATE" -Parameters $AggressiveParams
    
    if ($StopOnError -and -not $Results["Aggressive"]) {
        Write-Host "Stopping execution due to error in Aggressive run (StopOnError flag set)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Skipping Aggressive run (SkipAggressive flag set)" -ForegroundColor Yellow
    Write-Host ""
}

# Balanced: Medium learning rate, moderate batches
if (-not $SkipBalanced) {
    $Results["Balanced"] = Invoke-TrainingRun -RunName "Balanced" -Description "BALANCED / MEDIUM LEARNING RATE" -Parameters $BalancedParams
    
    if ($StopOnError -and -not $Results["Balanced"]) {
        Write-Host "Stopping execution due to error in Balanced run (StopOnError flag set)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Skipping Balanced run (SkipBalanced flag set)" -ForegroundColor Yellow
    Write-Host ""
}

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "BATCH TRAINING SUMMARY" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan

$SuccessCount = 0
$TotalCount = 0

foreach ($run in $Results.Keys) {
    $TotalCount++
    if ($Results[$run]) {
        $SuccessCount++
        Write-Host "$run`: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "$run`: FAILED" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Completed: $SuccessCount/$TotalCount runs successful" -ForegroundColor $(if ($SuccessCount -eq $TotalCount) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "Check the following for results:" -ForegroundColor White
Write-Host "  - Log files in TrainingBuild directory" -ForegroundColor Cyan
Write-Host "  - TensorBoard logs: Intermediate\LearningAgents\TensorBoard\runs" -ForegroundColor Cyan
Write-Host "  - Neural network snapshots in Intermediate directory" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view TensorBoard, run: .\scripts\run-tensorboard.ps1" -ForegroundColor Green

# Exit with appropriate code
if ($SuccessCount -eq $TotalCount) {
    Write-Host ""
    Write-Host "All training runs completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "Some training runs failed. Check logs for details." -ForegroundColor Yellow
    exit 1
}
