# Headless Training Launcher for FPSGame
# This script launches the packaged game in headless mode for training
# Usage: .\scripts\run-training-headless.ps1 [-TrainingBuildDir "TrainingBuild"] [-MapName "P_LearningAgentsTrial"] [-LogFile "training_log.log"] [-TimeoutMinutes 30]

param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$TrainingBuildDir = "TrainingBuild",
    [string]$MapName = "P_LearningAgentsTrial1",  # Default learning map
    [string]$LogFile = "fpscharacter_training.log",
    [string]$ExeName = "FPSGame.exe",
    [int]$RandomSeed = 1234,
    [float]$LearningRatePolicy = 0.0001,
    [float]$LearningRateCritic = 0.001,
    [float]$EpsilonClip = 0.2,
    [int]$PolicyBatchSize = 1024,
    [int]$CriticBatchSize = 4096,
    [int]$IterationsPerGather = 32,
    [int]$NumberOfIterations = 1000000,
    [float]$DiscountFactor = 0.99,
    [float]$GaeLambda = 0.95,
    [float]$ActionEntropyWeight = 0.0,
    [int]$TimeoutMinutes = 0,       # 0 or negative => run indefinitely
    [switch]$KillTreeOnTimeout = $true,
    # Obstacle configuration parameters
    [string]$UseObstacles = "true",
    [int]$MaxObstacles = 8,
    [float]$MinObstacleSize = 100.0,
    [float]$MaxObstacleSize = 300.0,
    [string]$ObstacleMode = "Static"  # "Static" or "Dynamic"
)

# Convert string parameters to appropriate types
$UseObstaclesBool = $UseObstacles -eq "true" -or $UseObstacles -eq "True" -or $UseObstacles -eq "1"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "FPSGAME HEADLESS TRAINING" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Training Build Dir: $TrainingBuildDir" -ForegroundColor Yellow
Write-Host "Map Name: $MapName" -ForegroundColor Yellow
Write-Host "Log File: $LogFile" -ForegroundColor Yellow
Write-Host "Executable: $ExeName" -ForegroundColor Yellow
Write-Host ""
Write-Host "PPO Hyperparameters:" -ForegroundColor Cyan
Write-Host "  Random Seed: $RandomSeed" -ForegroundColor White
Write-Host "  Learning Rate Policy: $LearningRatePolicy" -ForegroundColor White
Write-Host "  Learning Rate Critic: $LearningRateCritic" -ForegroundColor White
Write-Host "  Epsilon Clip: $EpsilonClip" -ForegroundColor White
Write-Host "  Policy Batch Size: $PolicyBatchSize" -ForegroundColor White
Write-Host "  Critic Batch Size: $CriticBatchSize" -ForegroundColor White
Write-Host "  Iterations Per Gather: $IterationsPerGather" -ForegroundColor White
Write-Host "  Number of Iterations: $NumberOfIterations" -ForegroundColor White
Write-Host "  Discount Factor: $DiscountFactor" -ForegroundColor White
Write-Host "  GAE Lambda: $GaeLambda" -ForegroundColor White
Write-Host "  Action Entropy Weight: $ActionEntropyWeight" -ForegroundColor White
Write-Host ""
Write-Host "Obstacle Configuration:" -ForegroundColor Cyan
Write-Host "  Use Obstacles: $UseObstaclesBool" -ForegroundColor White
Write-Host "  Max Obstacles: $MaxObstacles" -ForegroundColor White
Write-Host "  Min Obstacle Size: $MinObstacleSize" -ForegroundColor White
Write-Host "  Max Obstacle Size: $MaxObstacleSize" -ForegroundColor White
Write-Host "  Obstacle Mode: $ObstacleMode" -ForegroundColor White

# Helper function to kill process tree
function Stop-ProcessTree {
    param([int]$ProcessId)
    try {
        # /T kills the whole tree; /F is force
        & taskkill /PID $ProcessId /T /F | Out-Null
        return $true
    } catch {
        Write-Warning "Failed to kill process tree for PID $ProcessId`: $($_.Exception.Message)"
        return $false
    }
}

# Find the executable
$BuildPath = Join-Path $ProjectPath $TrainingBuildDir
$ExeFiles = Get-ChildItem -Path $BuildPath -Filter $ExeName -Recurse

if ($ExeFiles.Count -eq 0) {
    Write-Error "Executable '$ExeName' not found in build directory: $BuildPath"
    Write-Error "Please run package-training.ps1 first to create the training build"
    exit 1
}

$GameExecutable = $ExeFiles[0].FullName
$ExeDirectory = $ExeFiles[0].DirectoryName

Write-Host "Found executable: $GameExecutable" -ForegroundColor Green

# Change to executable directory for proper relative path resolution
Push-Location $ExeDirectory

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "LAUNCHING HEADLESS TRAINING" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Command Line Arguments:" -ForegroundColor Yellow
Write-Host "  Map: $MapName" -ForegroundColor White
Write-Host "  Headless Training: Enabled (forces Training mode)" -ForegroundColor White
Write-Host "  Null RHI: Enabled (no rendering)" -ForegroundColor White
Write-Host "  No Sound: Enabled" -ForegroundColor White
Write-Host "  Logging: Enabled to $LogFile" -ForegroundColor White

# Build command line arguments for headless training
$GameArgs = @(
    $MapName                    # Load the training map
    "-headless-training"        # Custom flag to identify headless training mode
    "-nullrhi"                  # Disable rendering for headless mode
    "-nosound"                  # Disable sound
    "-log"                      # Enable logging to console
    "-log=$LogFile"             # Log to specific file
    "-unattended"               # Run without user interaction
    "-nothreading"              # Some training setups work better without threading
    "-NoVerifyGC"               # Skip garbage collection verification for performance
    "-NoLoadStartupPackages"    # Skip loading startup packages for faster boot
    "-FORCELOGFLUSH"            # Force log flushing for real-time monitoring
    "-ini:Engine:[Core.Log]:LogPython=Verbose"  # Enable Python logging for Learning Agents
    "-RandomSeed=$RandomSeed"   # Random seed for reproducible training
    "-LearningRatePolicy=$LearningRatePolicy"  # Policy learning rate
    "-LearningRateCritic=$LearningRateCritic"  # Critic learning rate
    "-EpsilonClip=$EpsilonClip"  # PPO clipping parameter
    "-PolicyBatchSize=$PolicyBatchSize"  # Policy batch size
    "-CriticBatchSize=$CriticBatchSize"  # Critic batch size
    "-IterationsPerGather=$IterationsPerGather"  # Training iterations per gather
    "-NumberOfIterations=$NumberOfIterations"  # Total training iterations
    "-DiscountFactor=$DiscountFactor"  # Reward discount factor
    "-GaeLambda=$GaeLambda"  # GAE lambda parameter
    "-ActionEntropyWeight=$ActionEntropyWeight"  # Action entropy weight
    "-UseObstacles=$UseObstaclesBool"  # Enable/disable obstacles
    "-MaxObstacles=$MaxObstacles"  # Maximum number of obstacles
    "-MinObstacleSize=$MinObstacleSize"  # Minimum obstacle size
    "-MaxObstacleSize=$MaxObstacleSize"  # Maximum obstacle size
    "-ObstacleMode=$ObstacleMode"  # Obstacle mode (Static/Dynamic)
)


# Debug: Show all game arguments
Write-Host "`nGame Arguments:" -ForegroundColor Cyan
foreach ($arg in $GameArgs) {
    Write-Host "  $arg" -ForegroundColor White
}

Write-Host "`nStarting headless training..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop training" -ForegroundColor Yellow
Write-Host "Monitor progress in: $LogFile" -ForegroundColor Cyan
Write-Host "TensorBoard logs will be in: Intermediate/LearningAgents/TensorBoard/runs" -ForegroundColor Cyan

Write-Host "`nExecuting command:" -ForegroundColor Gray
Write-Host "$ExeName $($GameArgs -join ' ')" -ForegroundColor Gray

try {
    # Start the training process (use different window style based on environment)
    $WindowStyle = if ($env:SSH_CLIENT -or $env:SSH_TTY) { "Normal" } else { "Hidden" }
    $Process = Start-Process -FilePath $GameExecutable -ArgumentList $GameArgs -WindowStyle $WindowStyle -PassThru
    
    Write-Host "`nTraining process started with PID: $($Process.Id)" -ForegroundColor Green
    Write-Host "Window style: $WindowStyle (SSH detected: $($env:SSH_CLIENT -or $env:SSH_TTY))" -ForegroundColor Cyan
    Write-Host "You can monitor the log file in another terminal with:" -ForegroundColor Cyan
    Write-Host "  Get-Content -Path '$LogFile' -Wait" -ForegroundColor White
    
    # Wait for completion with optional timeout
    Write-Host "`nWaiting for training to complete..." -ForegroundColor Yellow

    $timedOut = $false
    if ($TimeoutMinutes -gt 0) {
        $ms = [int]($TimeoutMinutes * 60 * 1000)
        Write-Host "Timeout set to $TimeoutMinutes minute(s)..." -ForegroundColor Cyan
        
        # Use a more robust timeout mechanism for SSH environments
        $timeoutReached = $false
        $job = Start-Job -ScriptBlock {
            param($procId, $timeoutMs)
            $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
            if ($proc) {
                $proc.WaitForExit($timeoutMs)
                return $proc.HasExited
            }
            return $true
        } -ArgumentList $Process.Id, $ms
        
        try {
            $exitedInTime = $job | Wait-Job -Timeout ($TimeoutMinutes * 60 + 10) | Receive-Job
            if (-not $exitedInTime) {
                $timeoutReached = $true
            }
        } catch {
            $timeoutReached = $true
        } finally {
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
        
        if ($timeoutReached) {
            $timedOut = $true
            Write-Warning "Timeout hit. Attempting to terminate the training process tree (PID $($Process.Id))..."
            if ($KillTreeOnTimeout) {
                $ok = Stop-ProcessTree -ProcessId $Process.Id
                if (-not $ok) {
                    # Fallback: try stopping just the root if taskkill failed
                    try { Stop-Process -Id $Process.Id -Force -ErrorAction Stop } catch {}
                }
            } else {
                try { Stop-Process -Id $Process.Id -Force -ErrorAction Stop } catch {}
            }
            # Give the OS a moment to tear down children
            Start-Sleep -Seconds 2
        }
    } else {
        Write-Host "Training will run indefinitely (Press Ctrl+C to stop)" -ForegroundColor Cyan
        $Process.WaitForExit()
    }

    # Determine exit code / messaging
    $ExitCode = $null
    try { $ExitCode = $Process.ExitCode } catch { $ExitCode = $null }

    if ($timedOut) {
        $ExitCode = -1
        Write-Host "`nTraining **terminated due to timeout** after $TimeoutMinutes minute(s)." -ForegroundColor Yellow
    } elseif ($ExitCode -eq 0) {
        Write-Host "`nTraining completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`nTraining completed with exit code: $ExitCode" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Failed to start training: $_"
    exit 1
} finally {
    # Return to original directory
    Pop-Location
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "TRAINING SESSION ENDED" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Check the following for results:" -ForegroundColor White
Write-Host "  - Log file: $ExeDirectory\$LogFile" -ForegroundColor Cyan
Write-Host "  - TensorBoard logs: $ProjectPath\Intermediate\LearningAgents\TensorBoard\runs" -ForegroundColor Cyan
Write-Host "  - Neural network snapshots in project Intermediate directory" -ForegroundColor Cyan

Write-Host "`nTo view TensorBoard, run: .\scripts\run-tensorboard.ps1" -ForegroundColor Green

# Training session completed
