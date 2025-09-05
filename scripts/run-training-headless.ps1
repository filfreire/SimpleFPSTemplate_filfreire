# Headless Training Launcher for FPSGame
# This script launches the packaged game in headless mode for training
# Usage: .\scripts\run-training-headless.ps1 [-TrainingBuildDir "TrainingBuild"] [-MapName "P_LearningAgentsTrial"] [-LogFile "training_log.log"]

param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$TrainingBuildDir = "TrainingBuild",
    [string]$MapName = "P_LearningAgentsTrial1",  # Default learning map
    [string]$LogFile = "fpscharacter_training.log",
    [string]$ExeName = "FPSGame.exe",
    [int]$MaxTrainingTime = 0  # 0 = unlimited, otherwise minutes
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "FPSGAME HEADLESS TRAINING" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Training Build Dir: $TrainingBuildDir" -ForegroundColor Yellow
Write-Host "Map Name: $MapName" -ForegroundColor Yellow
Write-Host "Log File: $LogFile" -ForegroundColor Yellow
Write-Host "Executable: $ExeName" -ForegroundColor Yellow

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
)

# Note: Timeout is handled by PowerShell, not Unreal Engine
if ($MaxTrainingTime -gt 0) {
    Write-Host "  Timeout: $MaxTrainingTime minutes (PowerShell managed)" -ForegroundColor White
}

Write-Host "`nStarting headless training..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop training" -ForegroundColor Yellow
Write-Host "Monitor progress in: $LogFile" -ForegroundColor Cyan
Write-Host "TensorBoard logs will be in: Intermediate/LearningAgents/TensorBoard/runs" -ForegroundColor Cyan

Write-Host "`nExecuting command:" -ForegroundColor Gray
Write-Host "$ExeName $($GameArgs -join ' ')" -ForegroundColor Gray

try {
    # Start the training process (hidden window)
    $Process = Start-Process -FilePath $GameExecutable -ArgumentList $GameArgs -WindowStyle Hidden -PassThru
    
    Write-Host "`nTraining process started with PID: $($Process.Id)" -ForegroundColor Green
    Write-Host "You can monitor the log file in another terminal with:" -ForegroundColor Cyan
    Write-Host "  Get-Content -Path '$LogFile' -Wait" -ForegroundColor White
    
    # Wait for the process to complete with optional timeout
    Write-Host "`nWaiting for training to complete..." -ForegroundColor Yellow
    
    if ($MaxTrainingTime -gt 0) {
        $TimeoutMs = $MaxTrainingTime * 60 * 1000  # Convert minutes to milliseconds
        Write-Host "Training will timeout after $MaxTrainingTime minutes" -ForegroundColor Yellow
        $Process.WaitForExit($TimeoutMs)
        
        if (!$Process.HasExited) {
            Write-Host "`nTraining timeout reached! Terminating process..." -ForegroundColor Yellow
            Write-Host "Process ID: $($Process.Id)" -ForegroundColor Yellow
            
            # Try graceful termination first
            try {
                $Process.CloseMainWindow()
                Start-Sleep -Seconds 2
            } catch {
                Write-Host "CloseMainWindow failed: $_" -ForegroundColor Yellow
            }
            
            # Force kill if still running
            if (!$Process.HasExited) {
                Write-Host "Force killing process..." -ForegroundColor Red
                try {
                    $Process.Kill()
                    $Process.WaitForExit(5000)  # Wait up to 5 seconds for cleanup
                } catch {
                    Write-Host "Kill failed: $_" -ForegroundColor Red
                }
            }
            
            # Double-check if process is still running
            if (!$Process.HasExited) {
                Write-Host "Process still running! Using taskkill..." -ForegroundColor Red
                try {
                    & taskkill /F /PID $Process.Id
                    Start-Sleep -Seconds 1
                } catch {
                    Write-Host "taskkill failed: $_" -ForegroundColor Red
                }
            }
            
            $ExitCode = -1
        } else {
            $ExitCode = $Process.ExitCode
        }
    } else {
        $Process.WaitForExit()
        $ExitCode = $Process.ExitCode
    }
    
    # Final verification
    if ($MaxTrainingTime -gt 0 -and $ExitCode -eq -1) {
        # Check if process is actually terminated
        try {
            $ProcessInfo = Get-Process -Id $Process.Id -ErrorAction SilentlyContinue
            if ($ProcessInfo) {
                Write-Host "`nWARNING: Process $($Process.Id) is still running!" -ForegroundColor Red
                Write-Host "You may need to manually kill it with: taskkill /F /PID $($Process.Id)" -ForegroundColor Red
            } else {
                Write-Host "`nProcess successfully terminated" -ForegroundColor Green
            }
        } catch {
            Write-Host "`nProcess appears to be terminated" -ForegroundColor Green
        }
    }
    
    if ($ExitCode -eq 0) {
        Write-Host "`nTraining completed successfully!" -ForegroundColor Green
    } elseif ($ExitCode -eq -1) {
        Write-Host "`nTraining terminated due to timeout" -ForegroundColor Yellow
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
