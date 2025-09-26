# Batch Training Script for FPSGame
# This script runs multiple headless training sessions with different random seeds
# Usage: .\scripts\run-batch-training.ps1 [-StartSeed 1] [-EndSeed 30] [-TimeoutMinutes 60] [-ConcurrentRuns 1]

param(
    [int]$StartSeed = 1,
    [int]$EndSeed = 30,
    [int]$TimeoutMinutes = 60,
    [int]$ConcurrentRuns = 1,
    [string]$ProjectPath = (Get-Location).Path,
    [string]$TrainingBuildDir = "TrainingBuild",
    [string]$MapName = "P_LearningAgentsTrial1",
    [string]$ExeName = "FPSGame.exe",
    [string]$ResultsDir = "BatchTrainingResults",
    [switch]$CleanupIntermediate = $false,
    [switch]$SkipExisting = $true,
    # Obstacle configuration parameters
    [bool]$UseObstacles = $false,
    [int]$MaxObstacles = 8,
    [float]$MinObstacleSize = 100.0,
    [float]$MaxObstacleSize = 300.0,
    [string]$ObstacleMode = "Static"  # "Static" or "Dynamic"
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "FPSGAME BATCH TRAINING" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Start Seed: $StartSeed" -ForegroundColor Yellow
Write-Host "End Seed: $EndSeed" -ForegroundColor Yellow
Write-Host "Total Runs: $($EndSeed - $StartSeed + 1)" -ForegroundColor Yellow
Write-Host "Timeout per run: $TimeoutMinutes minutes" -ForegroundColor Yellow
Write-Host "Concurrent runs: $ConcurrentRuns" -ForegroundColor Yellow
Write-Host "Results directory: $ResultsDir" -ForegroundColor Yellow
Write-Host "Cleanup intermediate: $CleanupIntermediate" -ForegroundColor Yellow
Write-Host "Skip existing: $SkipExisting" -ForegroundColor Yellow
Write-Host ""
Write-Host "Obstacle Configuration:" -ForegroundColor Cyan
Write-Host "  Use Obstacles: $UseObstacles" -ForegroundColor White
Write-Host "  Max Obstacles: $MaxObstacles" -ForegroundColor White
Write-Host "  Min Obstacle Size: $MinObstacleSize" -ForegroundColor White
Write-Host "  Max Obstacle Size: $MaxObstacleSize" -ForegroundColor White
Write-Host "  Obstacle Mode: $ObstacleMode" -ForegroundColor White

# Create results directory
$ResultsPath = Join-Path $ProjectPath $ResultsDir
if (-not (Test-Path $ResultsPath)) {
    New-Item -ItemType Directory -Path $ResultsPath -Force | Out-Null
    Write-Host "Created results directory: $ResultsPath" -ForegroundColor Green
}

# Create subdirectories for organized results
$LogsDir = Join-Path $ResultsPath "Logs"
$TensorBoardDir = Join-Path $ResultsPath "TensorBoard"
$NeuralNetworksDir = Join-Path $ResultsPath "NeuralNetworks"
$SummaryDir = Join-Path $ResultsPath "Summary"

@($LogsDir, $TensorBoardDir, $NeuralNetworksDir, $SummaryDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

Write-Host "`nResults will be organized in:" -ForegroundColor Cyan
Write-Host "  - Logs: $LogsDir" -ForegroundColor White
Write-Host "  - TensorBoard: $TensorBoardDir" -ForegroundColor White
Write-Host "  - Neural Networks: $NeuralNetworksDir" -ForegroundColor White
Write-Host "  - Summary: $SummaryDir" -ForegroundColor White

# Initialize tracking variables
$CompletedRuns = @()
$FailedRuns = @()
$SkippedRuns = @()
$StartTime = Get-Date

# Function to run a single training session
function Start-TrainingSession {
    param(
        [int]$Seed,
        [string]$SessionId
    )
    
    $LogFile = "training_seed_$Seed.log"
    $LogPath = Join-Path $LogsDir $LogFile
    
    # Check if we should skip this run
    if ($SkipExisting -and (Test-Path $LogPath)) {
        Write-Host "Skipping seed $Seed - log file already exists" -ForegroundColor Yellow
        return "SKIPPED"
    }
    
    Write-Host "`nStarting training session $SessionId (Seed: $Seed)..." -ForegroundColor Green
    Write-Host "Log file: $LogFile" -ForegroundColor Cyan
    
    try {
        # Run the training session
        $Process = Start-Process -FilePath "powershell" -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-File", "scripts/run-training-headless.ps1",
            "-RandomSeed", $Seed,
            "-LogFile", $LogFile,
            "-TimeoutMinutes", $TimeoutMinutes,
            "-UseObstacles", $UseObstacles.ToString().ToLower(),
            "-MaxObstacles", $MaxObstacles,
            "-MinObstacleSize", $MinObstacleSize,
            "-MaxObstacleSize", $MaxObstacleSize,
            "-ObstacleMode", $ObstacleMode
        ) -WindowStyle Hidden -PassThru -WorkingDirectory $ProjectPath
        
        Write-Host "Training process started with PID: $($Process.Id)" -ForegroundColor Green
        
        # Wait for completion with timeout - use more robust approach for SSH
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $timeoutMs = $TimeoutMinutes * 60 * 1000
        $checkInterval = 5000  # Check every 5 seconds
        
        while (-not $Process.HasExited -and $timer.ElapsedMilliseconds -lt $timeoutMs) {
            Start-Sleep -Milliseconds $checkInterval
            
            # Check if process is still running
            try {
                $proc = Get-Process -Id $Process.Id -ErrorAction Stop
                if ($proc.HasExited) {
                    break
                }
            } catch {
                # Process no longer exists
                break
            }
        }
        
        $timer.Stop()
        
        if (-not $Process.HasExited -and $timer.ElapsedMilliseconds -ge $timeoutMs) {
            Write-Warning "Training session $SessionId timed out after $($timer.Elapsed.TotalMinutes.ToString('F1')) minutes"
            
            # Enhanced process termination - find and kill actual game processes
            Write-Host "Attempting to terminate training processes..." -ForegroundColor Yellow
            
            # First, try to find and kill the actual game executable processes
            $GameProcesses = Get-Process -Name "FPSGame" -ErrorAction SilentlyContinue
            if ($GameProcesses) {
                Write-Host "Found $($GameProcesses.Count) FPSGame.exe process(es)" -ForegroundColor Cyan
                foreach ($GameProc in $GameProcesses) {
                    Write-Host "Terminating FPSGame.exe (PID: $($GameProc.Id)) and its process tree..." -ForegroundColor Yellow
                    
                    # Method 1: Use taskkill with /T flag to kill process tree
                    $taskkillResult = & taskkill /PID $GameProc.Id /T /F 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "taskkill /T /F succeeded for PID $($GameProc.Id)" -ForegroundColor Green
                    } else {
                        Write-Warning "taskkill /T /F failed for PID $($GameProc.Id): $taskkillResult"
                        
                        # Method 2: Fallback - try to kill child processes manually
                        Write-Host "Attempting manual child process termination..." -ForegroundColor Yellow
                        try {
                            $childProcesses = Get-WmiObject Win32_Process | Where-Object { $_.ParentProcessId -eq $GameProc.Id }
                            foreach ($child in $childProcesses) {
                                Write-Host "Killing child process: $($child.ProcessName) (PID: $($child.ProcessId))" -ForegroundColor Gray
                                & taskkill /PID $child.ProcessId /F 2>$null
                            }
                            
                            # Now try to kill the main process again
                            & taskkill /PID $GameProc.Id /F 2>$null
                            Write-Host "Manual termination attempt completed for PID $($GameProc.Id)" -ForegroundColor Yellow
                        } catch {
                            Write-Warning "Manual child process termination failed: $($_.Exception.Message)"
                        }
                    }
                }
            } else {
                Write-Host "No FPSGame.exe processes found" -ForegroundColor Yellow
            }
            
            # Also terminate the PowerShell wrapper process
            Write-Host "Terminating PowerShell wrapper process (PID: $($Process.Id))..." -ForegroundColor Yellow
            try { 
                Stop-Process -Id $Process.Id -Force -ErrorAction Stop
                Write-Host "PowerShell process terminated successfully" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to terminate PowerShell process: $($_.Exception.Message)"
            }
            
            # Give processes time to terminate
            Start-Sleep -Seconds 3
            
            # Verify termination with multiple attempts
            $maxVerificationAttempts = 3
            $verificationAttempt = 0
            $allProcessesTerminated = $false
            
            while ($verificationAttempt -lt $maxVerificationAttempts -and -not $allProcessesTerminated) {
                $verificationAttempt++
                Write-Host "Verification attempt $verificationAttempt/$maxVerificationAttempts..." -ForegroundColor Cyan
                
                $RemainingGameProcesses = Get-Process -Name "FPSGame" -ErrorAction SilentlyContinue
                if ($RemainingGameProcesses) {
                    Write-Warning "Warning: $($RemainingGameProcesses.Count) FPSGame.exe process(es) still running"
                    
                    # Try one more aggressive termination attempt
                    foreach ($remainingProc in $RemainingGameProcesses) {
                        Write-Host "Force killing remaining process PID $($remainingProc.Id)..." -ForegroundColor Red
                        try {
                            # Try multiple termination methods
                            & taskkill /PID $remainingProc.Id /F 2>$null
                            Start-Sleep -Milliseconds 500
                            
                            # If still running, try PowerShell Stop-Process
                            $stillRunning = Get-Process -Id $remainingProc.Id -ErrorAction SilentlyContinue
                            if ($stillRunning) {
                                Stop-Process -Id $remainingProc.Id -Force -ErrorAction Stop
                            }
                        } catch {
                            Write-Warning "Failed to terminate remaining process PID $($remainingProc.Id): $($_.Exception.Message)"
                        }
                    }
                    
                    Start-Sleep -Seconds 2
                } else {
                    $allProcessesTerminated = $true
                    Write-Host "All FPSGame.exe processes successfully terminated" -ForegroundColor Green
                }
            }
            
            # Final verification
            $FinalGameProcesses = Get-Process -Name "FPSGame" -ErrorAction SilentlyContinue
            if ($FinalGameProcesses) {
                Write-Error "CRITICAL: $($FinalGameProcesses.Count) FPSGame.exe process(es) still running after all termination attempts!"
                Write-Error "Manual intervention may be required to terminate these processes."
                foreach ($proc in $FinalGameProcesses) {
                    Write-Error "  - PID: $($proc.Id), ProcessName: $($proc.ProcessName)"
                }
            } else {
                Write-Host "SUCCESS: All FPSGame.exe processes confirmed terminated" -ForegroundColor Green
            }
            
            return "TIMEOUT"
        }
        
        $ExitCode = $Process.ExitCode
        if ($ExitCode -eq 0) {
            Write-Host "Training session $SessionId completed successfully!" -ForegroundColor Green
            return "SUCCESS"
        } else {
            Write-Host "Training session $SessionId completed with exit code: $ExitCode" -ForegroundColor Yellow
            return "FAILED"
        }
        
    } catch {
        Write-Error "Failed to start training session $SessionId`: $($_.Exception.Message)"
        return "ERROR"
    }
}

# Function to copy results after training
function Copy-TrainingResults {
    param(
        [int]$Seed,
        [string]$Status
    )
    
    if ($Status -eq "SUCCESS" -or $Status -eq "TIMEOUT") {
        # Copy log file
        $SourceLog = Join-Path (Join-Path $ProjectPath "TrainingBuild\Windows\FPSGame\Saved\Logs") "training_seed_$Seed.log"
        $DestLog = Join-Path $LogsDir "training_seed_$Seed.log"
        
        Write-Host "Attempting to copy log file for seed $Seed..." -ForegroundColor Cyan
        Write-Host "Source: $SourceLog" -ForegroundColor Gray
        Write-Host "Destination: $DestLog" -ForegroundColor Gray
        
        if (Test-Path $SourceLog) {
            Copy-Item $SourceLog $DestLog -Force
            Write-Host "Copied log file: $SourceLog -> $DestLog" -ForegroundColor Green
        } else {
            Write-Warning "Log file not found: $SourceLog"
            # Check if the directory exists
            $LogDir = Split-Path $SourceLog -Parent
            if (Test-Path $LogDir) {
                Write-Host "Log directory exists: $LogDir" -ForegroundColor Yellow
                $AvailableLogs = Get-ChildItem $LogDir -Filter "*.log" | Select-Object Name
                if ($AvailableLogs) {
                    Write-Host "Available log files:" -ForegroundColor Yellow
                    $AvailableLogs | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
                } else {
                    Write-Host "No .log files found in directory" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Log directory does not exist: $LogDir" -ForegroundColor Red
            }
        }
        
        # Copy TensorBoard runs
        $TensorBoardSource = Join-Path $ProjectPath "Intermediate\LearningAgents\TensorBoard\runs"
        if (Test-Path $TensorBoardSource) {
            $LatestRun = Get-ChildItem $TensorBoardSource | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($LatestRun) {
                $TensorBoardDest = Join-Path $TensorBoardDir "seed_$Seed"
                Copy-Item $LatestRun.FullName $TensorBoardDest -Recurse -Force
            }
        }
        
        # Copy neural network files
        $NeuralNetSource = Join-Path $ProjectPath "Intermediate\LearningAgents\Training0"
        if (Test-Path $NeuralNetSource) {
            $NeuralNetDest = Join-Path $NeuralNetworksDir "seed_$Seed"
            Copy-Item $NeuralNetSource $NeuralNetDest -Recurse -Force
        }
        
        # Cleanup intermediate files if requested
        if ($CleanupIntermediate) {
            if (Test-Path $TensorBoardSource) {
                Remove-Item $TensorBoardSource -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $NeuralNetSource) {
                Remove-Item $NeuralNetSource -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Main training loop
Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "STARTING BATCH TRAINING" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan

$CurrentRun = 1
$TotalRuns = $EndSeed - $StartSeed + 1

for ($Seed = $StartSeed; $Seed -le $EndSeed; $Seed++) {
    $SessionId = "Run $CurrentRun/$TotalRuns"
    Write-Host "`n[$SessionId] Processing seed $Seed..." -ForegroundColor Cyan
    
    $Status = Start-TrainingSession -Seed $Seed -SessionId $SessionId
    
    # Track results
    switch ($Status) {
        "SUCCESS" { $CompletedRuns += $Seed }
        "FAILED" { $FailedRuns += $Seed }
        "TIMEOUT" { $FailedRuns += $Seed }
        "ERROR" { $FailedRuns += $Seed }
        "SKIPPED" { $SkippedRuns += $Seed }
    }
    
    # Copy results
    Copy-TrainingResults -Seed $Seed -Status $Status
    
    $CurrentRun++
    
    # Add delay between runs to avoid resource conflicts
    if ($CurrentRun -le $TotalRuns) {
        Write-Host "Waiting 30 seconds before next run..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
}

# Generate summary report
$EndTime = Get-Date
$TotalDuration = $EndTime - $StartTime

$SummaryReport = @"
FPSGAME BATCH TRAINING SUMMARY REPORT
=====================================
Start Time: $($StartTime.ToString("yyyy-MM-dd HH:mm:ss"))
End Time: $($EndTime.ToString("yyyy-MM-dd HH:mm:ss"))
Total Duration: $($TotalDuration.ToString("hh\:mm\:ss"))

CONFIGURATION:
- Seed Range: $StartSeed to $EndSeed
- Total Runs: $TotalRuns
- Timeout per run: $TimeoutMinutes minutes
- Concurrent runs: $ConcurrentRuns

RESULTS:
- Successful runs: $($CompletedRuns.Count) - Seeds: $($CompletedRuns -join ', ')
- Failed runs: $($FailedRuns.Count) - Seeds: $($FailedRuns -join ', ')
- Skipped runs: $($SkippedRuns.Count) - Seeds: $($SkippedRuns -join ', ')

FILES GENERATED:
- Log files: $LogsDir
- TensorBoard runs: $TensorBoardDir
- Neural network files: $NeuralNetworksDir
- This summary: $SummaryDir

NEXT STEPS:
1. Review individual log files for detailed training progress
2. Use TensorBoard to visualize training metrics: .\scripts\run-tensorboard.ps1 --log-dir "$TensorBoardDir"
3. Compare neural network performance across different seeds
4. Analyze results to determine optimal hyperparameters
"@

$SummaryFile = Join-Path $SummaryDir "batch_training_summary_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$SummaryReport | Out-File -FilePath $SummaryFile -Encoding UTF8

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "BATCH TRAINING COMPLETED" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Total Duration: $($TotalDuration.ToString("hh\:mm\:ss"))" -ForegroundColor Yellow
Write-Host "Successful runs: $($CompletedRuns.Count)/$TotalRuns" -ForegroundColor Green
Write-Host "Failed runs: $($FailedRuns.Count)/$TotalRuns" -ForegroundColor Red
Write-Host "Skipped runs: $($SkippedRuns.Count)/$TotalRuns" -ForegroundColor Yellow

Write-Host "`nResults saved to: $ResultsPath" -ForegroundColor Cyan
Write-Host "Summary report: $SummaryFile" -ForegroundColor Cyan

Write-Host "`nTo view TensorBoard for all runs:" -ForegroundColor Green
Write-Host ".\scripts\run-tensorboard.ps1 --log-dir `"$TensorBoardDir`"" -ForegroundColor White

# Batch training completed
