# Batch Training Runner for SimpleFPSTemplate_filfreire - 10 seeds Version
# This script runs multiple training configurations with 30 random seeds each
# All 10 seeds run in parallel for each flavor
# Usage: .\scripts\run-batch-special-30seeds.ps1

param(
    [switch]$SkipConservative = $false,
    [switch]$SkipAggressive = $false,
    [switch]$SkipModerate = $false,
    [switch]$StopOnError = $false,
    [string]$ResultsDir = "SpecialBatchResults_10Seeds"
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "SIMPLEFPSTEMPLATE_FILFREIRE BATCH TRAINING RUNNER - 10 seeds" -ForegroundColor Green
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

# Function to run a single training instance
function Invoke-SingleTrainingRun {
    param(
        [string]$RunName,
        [string]$Description,
        [hashtable]$Parameters,
        [int]$Seed
    )
    
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "RUN $RunName`_SEED_$Seed`: $Description" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Cyan
    
    # Create a copy of parameters and set the specific seed
    $RunParams = $Parameters.Clone()
    $RunParams.RandomSeed = $Seed
    
    # Display parameters
    Write-Host "Parameters:" -ForegroundColor White
    foreach ($key in $RunParams.Keys) {
        Write-Host "  $key`: $($RunParams[$key])" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Create unique log file name
    $LogFile = "special_${RunName}_seed_$Seed.log"
    
    # Build the command arguments as a string
    $cmdArgs = @()
    foreach ($key in $RunParams.Keys) {
        # Ensure RandomSeed is passed as integer to avoid type conversion issues
        if ($key -eq "RandomSeed") {
            $cmdArgs += "-$key $([int]$RunParams[$key])"
        } else {
            # Convert decimal separator from comma to dot for proper PowerShell parsing
            $value = $RunParams[$key].ToString()
            if ($value -match '^\d+,\d+$') {
                $value = $value -replace ',', '.'
            }
            $cmdArgs += "-$key $value"
        }
    }
    
    # Add log file parameter
    $cmdArgs += "-LogFile $LogFile"
    
    $commandString = ".\scripts\run-training-headless.ps1 " + ($cmdArgs -join ' ')
    
    Write-Host "Executing training run for seed $Seed..." -ForegroundColor Green
    Write-Host "Log file: $LogFile" -ForegroundColor Cyan
    Write-Host "Command: $commandString" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Execute the training script using Invoke-Expression to properly parse the command
        Invoke-Expression $commandString
        
        # Check exit code - treat timeout (-1) as successful
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1) {
            if ($LASTEXITCODE -eq -1) {
                Write-Host "Run $RunName`_SEED_$Seed completed with timeout (this is expected for testing)" -ForegroundColor Yellow
            } else {
                Write-Host "Run $RunName`_SEED_$Seed completed successfully!" -ForegroundColor Green
            }
            
            # Copy results
            Copy-TrainingResults -RunName $RunName -LogFile $LogFile -Seed $Seed
            return $true
        } else {
            Write-Host "Run $RunName`_SEED_$Seed failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Run $RunName`_SEED_$Seed failed with error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to run all training instances in parallel
function Invoke-TrainingBatch {
    param(
        [string]$RunName,
        [string]$Description,
        [hashtable]$Parameters,
        [int[]]$Seeds
    )
    
    Write-Host "======================================" -ForegroundColor Magenta
    Write-Host "$RunName`: $Description" -ForegroundColor Yellow
    Write-Host "Seeds: $($Seeds -join ', ')" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Create jobs for parallel execution
    $Jobs = @()
    $JobResults = @{}
    
    # Start all training jobs
    foreach ($Seed in $Seeds) {
        Write-Host "Starting training job for seed $Seed..." -ForegroundColor Green
        
        # Create a script block for the job
        $JobScript = {
            param($RunName, $Description, $Parameters, $Seed, $ProjectDir)
            
            # Set working directory
            Set-Location $ProjectDir
            
            # Load the training function (we'll need to redefine it in the job scope)
            function Invoke-SingleTrainingRun {
                param(
                    [string]$RunName,
                    [string]$Description,
                    [hashtable]$Parameters,
                    [int]$Seed
                )
                
                # Create a copy of parameters and set the specific seed
                $RunParams = $Parameters.Clone()
                $RunParams.RandomSeed = $Seed
                
                # Create unique log file name
                $LogFile = "special_${RunName}_seed_$Seed.log"
                
                # Build the command arguments as a string
                $cmdArgs = @()
                foreach ($key in $RunParams.Keys) {
                    if ($key -eq "RandomSeed") {
                        $cmdArgs += "-$key $([int]$RunParams[$key])"
                    } else {
                        $value = $RunParams[$key].ToString()
                        if ($value -match '^\d+,\d+$') {
                            $value = $value -replace ',', '.'
                        }
                        $cmdArgs += "-$key $value"
                    }
                }
                
                $cmdArgs += "-LogFile $LogFile"
                $commandString = ".\scripts\run-training-headless.ps1 " + ($cmdArgs -join ' ')
                
                try {
                    Invoke-Expression $commandString
                    return @{
                        Success = ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1)
                        ExitCode = $LASTEXITCODE
                        LogFile = $LogFile
                        Seed = $Seed
                    }
                } catch {
                    return @{
                        Success = $false
                        ExitCode = -999
                        LogFile = $LogFile
                        Seed = $Seed
                        Error = $_.Exception.Message
                    }
                }
            }
            
            # Execute the training
            return Invoke-SingleTrainingRun -RunName $RunName -Description $Description -Parameters $Parameters -Seed $Seed
        }
        
        # Start the job
        $Job = Start-Job -ScriptBlock $JobScript -ArgumentList $RunName, $Description, $Parameters, $Seed, $ProjectDir
        $Jobs += $Job
        $JobResults[$Seed] = $Job
    }
    
    Write-Host "Started $($Jobs.Count) parallel training jobs. Waiting for completion..." -ForegroundColor Cyan
    Write-Host "Training will run for 20 minutes per instance..." -ForegroundColor Yellow
    Write-Host ""
    
    # Wait for all jobs to complete
    $Jobs | Wait-Job | Out-Null
    
    # Collect results
    $BatchResults = @{}
    $SuccessCount = 0
    $TotalCount = $Jobs.Count
    
    foreach ($Job in $Jobs) {
        $Result = Receive-Job -Job $Job
        $Seed = $Result.Seed
        $BatchResults[$Seed] = $Result.Success
        
        if ($Result.Success) {
            $SuccessCount++
            Write-Host "Seed $Seed`: SUCCESS" -ForegroundColor Green
        } else {
            Write-Host "Seed $Seed`: FAILED (Exit Code: $($Result.ExitCode))" -ForegroundColor Red
            if ($Result.Error) {
                Write-Host "  Error: $($Result.Error)" -ForegroundColor Red
            }
        }
        
        # Copy results for successful runs
        if ($Result.Success) {
            Copy-TrainingResults -RunName $RunName -LogFile $Result.LogFile -Seed $Seed
        }
        
        Remove-Job -Job $Job
    }
    
    Write-Host ""
    Write-Host "$RunName completed: $SuccessCount/$TotalCount successful" -ForegroundColor $(if ($SuccessCount -eq $TotalCount) { "Green" } else { "Yellow" })
    Write-Host ""
    
    return $BatchResults
}

# Function to copy training results
function Copy-TrainingResults {
    param(
        [string]$RunName,
        [string]$LogFile,
        [int]$Seed
    )
    
    Write-Host "Copying results for $RunName`_seed_$Seed..." -ForegroundColor Cyan
    
    # Copy log file - check multiple possible locations
    $PossibleLogPaths = @(
        Join-Path (Join-Path $ProjectDir "TrainingBuild\Windows\FPSGame\Saved\Logs") $LogFile,
        Join-Path (Join-Path $ProjectDir "TrainingBuild\Windows\FPSGame") $LogFile,
        Join-Path (Join-Path $ProjectDir "TrainingBuild\Windows") $LogFile,
        Join-Path $ProjectDir $LogFile
    )
    
    $LogCopied = $false
    foreach ($SourceLog in $PossibleLogPaths) {
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
    }
    
    # Copy TensorBoard runs
    $TensorBoardSource = Join-Path $ProjectDir "Intermediate\LearningAgents\TensorBoard\runs"
    if (Test-Path $TensorBoardSource) {
        $LatestRun = Get-ChildItem $TensorBoardSource | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($LatestRun) {
            $TensorBoardDest = Join-Path $TensorBoardDir "${RunName}_seed_$Seed"
            Copy-Item $LatestRun.FullName $TensorBoardDest -Recurse -Force
            Write-Host "Copied TensorBoard run: $($LatestRun.Name) -> ${RunName}_seed_$Seed" -ForegroundColor Green
        }
    }
    
    # Copy neural network files
    $NeuralNetSource = Join-Path $ProjectDir "Intermediate\LearningAgents\Training0"
    if (Test-Path $NeuralNetSource) {
        $NeuralNetDest = Join-Path $NeuralNetworksDir "${RunName}_seed_$Seed"
        Copy-Item $NeuralNetSource $NeuralNetDest -Recurse -Force
        Write-Host "Copied neural network files: Training0 -> ${RunName}_seed_$Seed" -ForegroundColor Green
    }
    
    Write-Host ""
}

# Clean up any orphaned processes before starting
Stop-OrphanedTrainingProcesses

# Define the three training configurations
$ConservativeParams = @{
    TimeoutMinutes = 20
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
    TimeoutMinutes = 20
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

$ModerateParams = @{
    TimeoutMinutes = 20
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
$AllResults = @{}
$StartTime = Get-Date

$AllSeeds = 1..10
# USING 1..10 for testing purposes; 

# Conservative: Low learning rate, small batches
if (-not $SkipConservative) {
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "STARTING CONSERVATIVE TRAINING RUNS" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    
    # Run all 10 seeds in parallel
    Write-Host "Running Conservative (All 10 Seeds in Parallel)..." -ForegroundColor Yellow
    $ConservativeResults = Invoke-TrainingBatch -RunName "Conservative" -Description "CONSERVATIVE / LOW LEARNING RATE" -Parameters $ConservativeParams -Seeds $AllSeeds
    $AllResults["Conservative"] = $ConservativeResults
    
    # Clean up processes between flavors
    Stop-OrphanedTrainingProcesses
} else {
    Write-Host "Skipping Conservative runs (SkipConservative flag set)" -ForegroundColor Yellow
    Write-Host ""
}

# Aggressive: High learning rate, large batches
if (-not $SkipAggressive) {
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "STARTING AGGRESSIVE TRAINING RUNS" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    
    # Run all 10 seeds in parallel
    Write-Host "Running Aggressive (All 10 Seeds in Parallel)..." -ForegroundColor Yellow
    $AggressiveResults = Invoke-TrainingBatch -RunName "Aggressive" -Description "AGGRESSIVE / HIGH LEARNING RATE" -Parameters $AggressiveParams -Seeds $AllSeeds
    $AllResults["Aggressive"] = $AggressiveResults
    
    # Clean up processes between flavors
    Stop-OrphanedTrainingProcesses
} else {
    Write-Host "Skipping Aggressive runs (SkipAggressive flag set)" -ForegroundColor Yellow
    Write-Host ""
}

# Moderate: Medium learning rate, moderate batches
if (-not $SkipModerate) {
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "STARTING MODERATE TRAINING RUNS" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    
    # Run all 10 seeds in parallel
    Write-Host "Running Moderate (All 10 seeds in Parallel)..." -ForegroundColor Yellow
    $ModerateResults = Invoke-TrainingBatch -RunName "Moderate" -Description "MODERATE / MEDIUM LEARNING RATE" -Parameters $ModerateParams -Seeds $AllSeeds
    $AllResults["Moderate"] = $ModerateResults
    
    # Final cleanup
    Stop-OrphanedTrainingProcesses
} else {
    Write-Host "Skipping Moderate runs (SkipModerate flag set)" -ForegroundColor Yellow
    Write-Host ""
}

# Generate summary report
$EndTime = Get-Date
$TotalDuration = $EndTime - $StartTime

# Calculate overall statistics
$TotalSuccessful = 0
$TotalRuns = 0
$FlavorStats = @{}

foreach ($flavor in @("Conservative", "Aggressive", "Moderate")) {
    $FlavorStats[$flavor] = @{
        Successful = 0
        Total = 0
    }
    
    if ($AllResults.ContainsKey($flavor)) {
        $flavorResults = $AllResults[$flavor]
        $successful = ($flavorResults.Values | Where-Object { $_ -eq $true }).Count
        $total = $flavorResults.Count
        
        $FlavorStats[$flavor].Successful = $successful
        $FlavorStats[$flavor].Total = $total
        $TotalSuccessful += $successful
        $TotalRuns += $total
    }
}

$SummaryReport = @"
SIMPLEFPSTEMPLATE_FILFREIRE SPECIAL BATCH TRAINING SUMMARY REPORT - 10 seeds
=============================================================================
Start Time: $($StartTime.ToString("yyyy-MM-dd HH:mm:ss"))
End Time: $($EndTime.ToString("yyyy-MM-dd HH:mm:ss"))
Total Duration: $($TotalDuration.ToString("hh\:mm\:ss"))

OVERALL RESULTS:
- Total successful runs: $TotalSuccessful
- Total failed runs: $($TotalRuns - $TotalSuccessful)
- Success rate: $([math]::Round(($TotalSuccessful / $TotalRuns) * 100, 2))%

DETAILED RESULTS BY FLAVOR:
"@

foreach ($flavor in @("Conservative", "Aggressive", "Moderate")) {
    $stats = $FlavorStats[$flavor]
    $successRate = if ($stats.Total -gt 0) { [math]::Round(($stats.Successful / $stats.Total) * 100, 2) } else { 0 }
    $SummaryReport += "`n- $flavor`: $($stats.Successful)/$($stats.Total) successful ($successRate%)"
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
3. Compare neural network performance across different configurations and seeds
4. Analyze results to determine optimal hyperparameters and seed sensitivity
"@

$SummaryFile = Join-Path $SummaryDir "special_batch_training_10seeds_summary_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$SummaryReport | Out-File -FilePath $SummaryFile -Encoding UTF8

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "BATCH TRAINING SUMMARY - 10 seeds" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan

foreach ($flavor in @("Conservative", "Aggressive", "Moderate")) {
    $stats = $FlavorStats[$flavor]
    $successRate = if ($stats.Total -gt 0) { [math]::Round(($stats.Successful / $stats.Total) * 100, 2) } else { 0 }
    $color = if ($stats.Successful -eq $stats.Total) { "Green" } elseif ($stats.Successful -gt 0) { "Yellow" } else { "Red" }
    Write-Host "$flavor`: $($stats.Successful)/$($stats.Total) successful ($successRate%)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Overall: $TotalSuccessful/$TotalRuns runs successful" -ForegroundColor $(if ($TotalSuccessful -eq $TotalRuns) { "Green" } else { "Yellow" })
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
if ($TotalSuccessful -eq $TotalRuns) {
    Write-Host ""
    Write-Host "All training runs completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "Some training runs failed. Check logs for details." -ForegroundColor Yellow
    exit 1
}
