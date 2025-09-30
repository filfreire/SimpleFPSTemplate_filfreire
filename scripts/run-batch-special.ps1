# Batch Training Runner for simplefpstemplate_filfreire
# This script runs multiple training configurations sequentially
# Usage: .\scripts\run-batch-special.ps1

param(
    [switch]$SkipConservative = $false,
    [switch]$SkipAggressive = $false,
    [switch]$SkipBalanced = $false,
    [switch]$StopOnError = $false,
    [string]$ResultsDir = "SpecialBatchResults"
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "simplefpstemplate_filfreire BATCH TRAINING RUNNER" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Set the project directory
$ProjectDir = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectDir

Write-Host "Project Directory: $ProjectDir" -ForegroundColor Yellow
Write-Host "Results Directory: $ResultsDir" -ForegroundColor Yellow
Write-Host ""

# Create results directory
$ResultsPath = Join-Path $ProjectDir $ResultsDir
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

Write-Host "Results will be organized in:" -ForegroundColor Cyan
Write-Host "  - Logs: $LogsDir" -ForegroundColor White
Write-Host "  - TensorBoard: $TensorBoardDir" -ForegroundColor White
Write-Host "  - Neural Networks: $NeuralNetworksDir" -ForegroundColor White
Write-Host "  - Summary: $SummaryDir" -ForegroundColor White
Write-Host ""

# Function to clean up orphaned training processes
function Stop-OrphanedTrainingProcesses {
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "CHECKING FOR ORPHANED TRAINING PROCESSES" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Cyan
    
    # Find and kill any running FPSGame processes
    $GameProcesses = Get-Process -Name "FPSGame" -ErrorAction SilentlyContinue
    if ($GameProcesses) {
        Write-Host "Found $($GameProcesses.Count) orphaned FPSGame.exe process(es)" -ForegroundColor Yellow
        foreach ($GameProc in $GameProcesses) {
            Write-Host "Terminating orphaned FPSGame.exe (PID: $($GameProc.Id)) and its process tree..." -ForegroundColor Yellow
            
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
    } else {
        Write-Host "No orphaned FPSGame.exe processes found" -ForegroundColor Green
    }
    
    Write-Host ""
}

# Clean up any orphaned processes before starting
Stop-OrphanedTrainingProcesses

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
    
    # Create unique log file name
    $LogFile = "special_${RunName}_seed_$($Parameters.RandomSeed).log"
    
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
    
    # Add log file parameter
    $cmdArgs += "-LogFile $LogFile"
    
    $commandString = ".\scripts\run-training-headless.ps1 " + ($cmdArgs -join ' ')
    
    Write-Host "Executing training run..." -ForegroundColor Green
    Write-Host "Log file: $LogFile" -ForegroundColor Cyan
    Write-Host "Command: $commandString" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Execute the training script using Invoke-Expression to properly parse the command
        Invoke-Expression $commandString
        
        # Check exit code - treat timeout (-1) as successful
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1) {
            if ($LASTEXITCODE -eq -1) {
                Write-Host "Run $RunName completed with timeout (this is expected for testing)" -ForegroundColor Yellow
            } else {
                Write-Host "Run $RunName completed successfully!" -ForegroundColor Green
            }
            
            # Copy results
            Copy-TrainingResults -RunName $RunName -LogFile $LogFile -Seed $Parameters.RandomSeed
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

# Function to copy training results
function Copy-TrainingResults {
    param(
        [string]$RunName,
        [string]$LogFile,
        [int]$Seed
    )
    
    Write-Host "Copying results for $RunName run..." -ForegroundColor Cyan
    
    # Copy log file - check multiple possible locations
    $PossibleLogPaths = @(
        Join-Path (Join-Path $ProjectDir "TrainingBuild\Windows\FPSGame\Saved\Logs") $LogFile,
        Join-Path (Join-Path $ProjectDir "TrainingBuild\Windows\FPSGame") $LogFile,
        Join-Path (Join-Path $ProjectDir "TrainingBuild\Windows") $LogFile,
        Join-Path $ProjectDir $LogFile
    )
    
    $LogCopied = $false
    foreach ($SourceLog in $PossibleLogPaths) {
        Write-Host "Checking for log file: $SourceLog" -ForegroundColor Gray
        if (Test-Path $SourceLog) {
            $DestLog = Join-Path $LogsDir $LogFile
            Copy-Item $SourceLog $DestLog -Force
            Write-Host "Copied log file: $SourceLog -> $DestLog" -ForegroundColor Green
            $LogCopied = $true
            break
        }
    }
    
    if (-not $LogCopied) {
        Write-Warning "Log file not found in any expected location: $LogFile"
        # Check what log files are actually available
        $LogDirs = @(
            Join-Path $ProjectDir "TrainingBuild\Windows\FPSGame\Saved\Logs",
            Join-Path $ProjectDir "TrainingBuild\Windows\FPSGame",
            Join-Path $ProjectDir "TrainingBuild\Windows",
            $ProjectDir
        )
        
        foreach ($LogDir in $LogDirs) {
            if (Test-Path $LogDir) {
                $AvailableLogs = Get-ChildItem $LogDir -Filter "*.log" -ErrorAction SilentlyContinue
                if ($AvailableLogs) {
                    Write-Host "Available log files in ${LogDir}:" -ForegroundColor Yellow
                    $AvailableLogs | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
                }
            }
        }
    }
    
    # Copy TensorBoard runs
    $TensorBoardSource = Join-Path $ProjectDir "Intermediate\LearningAgents\TensorBoard\runs"
    if (Test-Path $TensorBoardSource) {
        $LatestRun = Get-ChildItem $TensorBoardSource | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($LatestRun) {
            $TensorBoardDest = Join-Path $TensorBoardDir "${RunName}_seed_$Seed"
            Copy-Item $LatestRun.FullName $TensorBoardDest -Recurse -Force
            Write-Host "Copied TensorBoard run: $($LatestRun.Name) -> ${RunName}_seed_$Seed" -ForegroundColor Green
        } else {
            Write-Warning "No TensorBoard runs found in: $TensorBoardSource"
        }
    } else {
        Write-Warning "TensorBoard source directory not found: $TensorBoardSource"
    }
    
    # Copy neural network files
    $NeuralNetSource = Join-Path $ProjectDir "Intermediate\LearningAgents\Training0"
    if (Test-Path $NeuralNetSource) {
        $NeuralNetDest = Join-Path $NeuralNetworksDir "${RunName}_seed_$Seed"
        Copy-Item $NeuralNetSource $NeuralNetDest -Recurse -Force
        Write-Host "Copied neural network files: Training0 -> ${RunName}_seed_$Seed" -ForegroundColor Green
    } else {
        Write-Warning "Neural network source directory not found: $NeuralNetSource"
    }
    
    Write-Host ""
}

# Define the three training configurations
$ConservativeParams = @{
    TimeoutMinutes = 35
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
    TimeoutMinutes = 35
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
    TimeoutMinutes = 35
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
$StartTime = Get-Date

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

# Generate summary report
$EndTime = Get-Date
$TotalDuration = $EndTime - $StartTime

$SummaryReport = @"
simplefpstemplate_filfreire SPECIAL BATCH TRAINING SUMMARY REPORT
==================================================
Start Time: $($StartTime.ToString("yyyy-MM-dd HH:mm:ss"))
End Time: $($EndTime.ToString("yyyy-MM-dd HH:mm:ss"))
Total Duration: $($TotalDuration.ToString("hh\:mm\:ss"))

CONFIGURATION:
- Conservative: Low learning rate, small batches (5 min timeout)
- Aggressive: High learning rate, large batches (5 min timeout)  
- Balanced: Medium learning rate, moderate batches (5 min timeout)

RESULTS:
- Successful runs: $($Results.Values | Where-Object { $_ -eq $true }).Count
- Failed runs: $($Results.Values | Where-Object { $_ -eq $false }).Count

DETAILED RESULTS:
"@

foreach ($run in $Results.Keys) {
    $status = if ($Results[$run]) { "SUCCESS" } else { "FAILED" }
    $SummaryReport += "`n- $run`: $status"
}

$SummaryReport += @"

FILES GENERATED:
- Log files: $LogsDir
- TensorBoard runs: $TensorBoardDir
- Neural network files: $NeuralNetworksDir
- This summary: $SummaryDir

NEXT STEPS:
1. Review individual log files for detailed training progress
2. Use TensorBoard to visualize training metrics: .\scripts\run-tensorboard.ps1 --log-dir "$TensorBoardDir"
3. Compare neural network performance across different configurations
4. Analyze results to determine optimal hyperparameters
"@

$SummaryFile = Join-Path $SummaryDir "special_batch_training_summary_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$SummaryReport | Out-File -FilePath $SummaryFile -Encoding UTF8

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
Write-Host "Total Duration: $($TotalDuration.ToString("hh\:mm\:ss"))" -ForegroundColor Yellow

Write-Host ""
Write-Host "Results saved to: $ResultsPath" -ForegroundColor Cyan
Write-Host "Summary report: $SummaryFile" -ForegroundColor Cyan

Write-Host ""
Write-Host "Check the following for results:" -ForegroundColor White
Write-Host "  - Log files: $LogsDir" -ForegroundColor Cyan
Write-Host "  - TensorBoard logs: $TensorBoardDir" -ForegroundColor Cyan
Write-Host "  - Neural network files: $NeuralNetworksDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view TensorBoard for all runs:" -ForegroundColor Green
Write-Host ".\scripts\run-tensorboard.ps1 --log-dir `"$TensorBoardDir`"" -ForegroundColor White

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
