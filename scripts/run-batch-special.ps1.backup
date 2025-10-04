# Batch Training Runner for CoopGameFleep
# This script runs multiple training configurations sequentially
# Usage: .\scripts\run-batch-special.ps1

param(
    [switch]$SkipConservative = $false,
    [switch]$SkipAggressive = $false,
    [switch]$SkipBalanced = $false,
    [switch]$StopOnError = $false,
    [string]$ResultsDir = "SpecialBatchResults",
    [int]$SeedsPerConfig = 30,
    [int]$ConcurrentRuns = 15,
    [int]$TimeoutMinutes = 5,
    [int]$SeedMinimum = 1,
    [int]$SeedMaximum = 2000000000,
    [string]$TrainingBuildDir = "TrainingBuild",
    [string]$MapName = "P_LearningAgentsTrial1",
    [string]$ExeName = "CoopGameFleep.exe",
    [bool]$UseObstacles = $false,
    [int]$MaxObstacles = 8,
    [float]$MinObstacleSize = 100.0,
    [float]$MaxObstacleSize = 300.0,
    [string]$ObstacleMode = "Static",
    [switch]$CleanupIntermediate = $false
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "COOPGAMEFLEEP BATCH TRAINING RUNNER" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

if ($SeedsPerConfig -le 0) {
    Write-Error "SeedsPerConfig must be greater than zero."
    exit 1
}

if ($ConcurrentRuns -le 0) {
    Write-Error "ConcurrentRuns must be at least 1."
    exit 1
}

if ($TimeoutMinutes -le 0) {
    Write-Error "TimeoutMinutes must be greater than zero for batch coordination."
    exit 1
}

if ($SeedMinimum -ge $SeedMaximum) {
    Write-Error "SeedMinimum must be less than SeedMaximum."
    exit 1
}

$ConcurrentRuns = [Math]::Max(1, $ConcurrentRuns)

# Set the project directory
$ProjectDir = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectDir

Write-Host "Project Directory: $ProjectDir" -ForegroundColor Yellow
Write-Host "Results Directory: $ResultsDir" -ForegroundColor Yellow
Write-Host "Seeds per configuration: $SeedsPerConfig" -ForegroundColor Yellow
Write-Host "Seed range: $SeedMinimum .. $SeedMaximum" -ForegroundColor Yellow
Write-Host "Concurrent runs: $ConcurrentRuns" -ForegroundColor Yellow
Write-Host "Timeout per run: $TimeoutMinutes minute(s)" -ForegroundColor Yellow
Write-Host "Use Obstacles: $UseObstacles" -ForegroundColor Yellow
Write-Host "Obstacle settings -> Max: $MaxObstacles, Min Size: $MinObstacleSize, Max Size: $MaxObstacleSize, Mode: $ObstacleMode" -ForegroundColor Yellow
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
    
    # Find and kill any running CoopGameFleep processes
    $GameProcesses = Get-Process -Name "CoopGameFleep" -ErrorAction SilentlyContinue
    if ($GameProcesses) {
        Write-Host "Found $($GameProcesses.Count) orphaned CoopGameFleep.exe process(es)" -ForegroundColor Yellow
        foreach ($GameProc in $GameProcesses) {
            Write-Host "Terminating orphaned CoopGameFleep.exe (PID: $($GameProc.Id)) and its process tree..." -ForegroundColor Yellow
            
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
            
            $RemainingGameProcesses = Get-Process -Name "CoopGameFleep" -ErrorAction SilentlyContinue
            if ($RemainingGameProcesses) {
                Write-Warning "Warning: $($RemainingGameProcesses.Count) CoopGameFleep.exe process(es) still running"
                
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
                Write-Host "All CoopGameFleep.exe processes successfully terminated" -ForegroundColor Green
            }
        }
        
        # Final verification
        $FinalGameProcesses = Get-Process -Name "CoopGameFleep" -ErrorAction SilentlyContinue
        if ($FinalGameProcesses) {
            Write-Error "CRITICAL: $($FinalGameProcesses.Count) CoopGameFleep.exe process(es) still running after all termination attempts!"
            Write-Error "Manual intervention may be required to terminate these processes."
            foreach ($proc in $FinalGameProcesses) {
                Write-Error "  - PID: $($proc.Id), ProcessName: $($proc.ProcessName)"
            }
        } else {
            Write-Host "SUCCESS: All CoopGameFleep.exe processes confirmed terminated" -ForegroundColor Green
        }
    } else {
        Write-Host "No orphaned CoopGameFleep.exe processes found" -ForegroundColor Green
    }
    
    Write-Host ""
}

# Clean up any orphaned processes before starting
Stop-OrphanedTrainingProcesses

# Helpers for task naming, parameter handling, and artifact collection
function Get-SafeTaskName {
    param(
        [string]$Name,
        [string]$Fallback = ""
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $Fallback
    }

    $Safe = $Name.Trim()
    $Safe = $Safe -replace '[^A-Za-z0-9_\-]', '_'
    $Safe = $Safe.Trim('_')

    if ([string]::IsNullOrWhiteSpace($Safe)) {
        return $Fallback
    }

    if ($Safe.Length -gt 60) {
        $Safe = $Safe.Substring(0, 60)
    }

    return $Safe
}

function New-UniqueTaskName {
    param(
        [string]$BaseName = "",
        [object]$Seed = $null
    )

    $SafeBase = Get-SafeTaskName -Name $BaseName -Fallback "run"
    if ([string]::IsNullOrWhiteSpace($SafeBase)) {
        $SafeBase = "run"
    }

    $GuidSegment = ([Guid]::NewGuid().ToString("N")).Substring(0, 12).ToLower()
    $Segments = @($SafeBase)

    if ($PSBoundParameters.ContainsKey('Seed') -and $Seed -ne $null) {
        $SeedValue = [int]$Seed
        $Segments += "seed"
        $Segments += $SeedValue
    }

    $Segments += $GuidSegment
    $Candidate = Get-SafeTaskName -Name ($Segments -join '-') -Fallback $GuidSegment

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        return $GuidSegment
    }

    return $Candidate
}

function Convert-ToInvariantString {
    param($Value)

    if ($Value -is [bool]) {
        return $Value.ToString().ToLower()
    }

    if ($Value -is [double] -or $Value -is [float] -or $Value -is [decimal]) {
        return [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0}", $Value)
    }

    return $Value.ToString()
}

function New-RandomSeeds {
    param(
        [int]$Count,
        [int]$Minimum = 1,
        [int]$Maximum = 2000000000
    )

    if ($Count -le 0) {
        return @()
    }

    if ($Minimum -ge $Maximum) {
        throw "Seed minimum must be less than maximum."
    }

    $Random = [System.Random]::new()
    $Set = New-Object System.Collections.Generic.HashSet[int]
    $Ordered = New-Object System.Collections.Generic.List[int]

    while ($Ordered.Count -lt $Count) {
        $Candidate = $Random.Next($Minimum, $Maximum)
        if ($Set.Add($Candidate)) {
            $Ordered.Add($Candidate)
        }
    }

    return $Ordered.ToArray()
}

function Ensure-ConfigDirectories {
    param(
        [string]$ConfigName,
        [string]$LogsRoot,
        [string]$TensorBoardRoot,
        [string]$NeuralNetworksRoot
    )

    $SafeName = Get-SafeTaskName -Name $ConfigName -Fallback $ConfigName
    $Paths = @{
        SafeName       = $SafeName
        Logs           = Join-Path $LogsRoot $SafeName
        TensorBoard    = Join-Path $TensorBoardRoot $SafeName
        NeuralNetworks = Join-Path $NeuralNetworksRoot $SafeName
    }

    foreach ($Path in $Paths.Values) {
        if ($Path -and -not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }

    return $Paths
}

function Start-TrainingProcess {
    param(
        [pscustomobject]$Run,
        [string]$ProjectDir,
        [string]$TrainingBuildDir,
        [string]$MapName,
        [string]$ExeName,
        [int]$TimeoutMinutes
    )

    $LogFileName = "special_{0}_seed_{1}.log" -f ($Run.ConfigSafeName.ToLower()), $Run.Seed
    $TaskName = New-UniqueTaskName -BaseName $Run.ConfigSafeName -Seed $Run.Seed

    $ArgumentList = @(
        "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $ProjectDir "scripts/run-training-headless.ps1"),
        "-ProjectPath", $ProjectDir,
        "-TrainingBuildDir", $TrainingBuildDir,
        "-MapName", $MapName,
        "-ExeName", $ExeName,
        "-RandomSeed", $Run.Seed,
        "-LogFile", $LogFileName,
        "-TimeoutMinutes", $TimeoutMinutes
    )

    if ($TaskName) {
        $ArgumentList += "-TrainingTaskName"
        $ArgumentList += $TaskName
    }

    foreach ($Key in $Run.Parameters.Keys) {
        $ArgumentList += "-$Key"
        $ArgumentList += (Convert-ToInvariantString -Value $Run.Parameters[$Key])
    }

    Write-Host "Launching [$($Run.ConfigName)] seed $($Run.Seed) (Run $($Run.Index))" -ForegroundColor Green
    Write-Host "  Task Name: $TaskName" -ForegroundColor Gray
    Write-Host "  Log File: $LogFileName" -ForegroundColor Gray

    $Process = Start-Process -FilePath "powershell" -ArgumentList $ArgumentList -WindowStyle Hidden -WorkingDirectory $ProjectDir -PassThru

    return [PSCustomObject]@{
        Process   = $Process
        Run       = $Run
        TaskName  = $TaskName
        LogFile   = $LogFileName
        StartTime = Get-Date
    }
}

function Get-FirstNonEmptyString {
    param(
        [object]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $null
        }

        return $Value
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        foreach ($Item in $Value) {
            $Candidate = Get-FirstNonEmptyString -Value $Item
            if ($null -ne $Candidate) {
                return $Candidate
            }
        }

        return $null
    }

    $Text = $Value.ToString()
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    return $Text
}

function Copy-TrainingArtifacts {
    param(
        [string]$ProjectDir,
        [pscustomobject]$Run,
        [string]$TaskName,
    [object]$LogFileName,
        [hashtable]$Destinations,
        [string]$Status,
        [switch]$CleanupIntermediate
    )

    foreach ($Path in $Destinations.Values) {
        if ($Path -and -not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }

    $LogFileName = Get-FirstNonEmptyString -Value $LogFileName

    $LogFileResolved = -not [string]::IsNullOrWhiteSpace($LogFileName)
    $LogCopied = $false

    if ($LogFileResolved) {
        $PossibleLogPaths = @(
            Join-Path (Join-Path $ProjectDir "TrainingBuild\Windows\CoopGameFleep\Saved\Logs") $LogFileName,
            Join-Path (Join-Path $ProjectDir "TrainingBuild\Windows\CoopGameFleep") $LogFileName,
            Join-Path (Join-Path $ProjectDir "TrainingBuild\Windows") $LogFileName,
            Join-Path $ProjectDir $LogFileName
        )

        foreach ($Source in $PossibleLogPaths) {
            if (Test-Path $Source) {
                $DestinationLog = Join-Path $Destinations.Logs $LogFileName
                Copy-Item $Source $DestinationLog -Force
                Write-Host "Copied log file: $Source -> $DestinationLog" -ForegroundColor Green
                $LogCopied = $true
                break
            }
        }

        if (-not $LogCopied) {
            Write-Warning "Log file not found for [$($Run.ConfigName)] seed $($Run.Seed): $LogFileName"
        }
    } else {
        Write-Warning "Log file name missing for [$($Run.ConfigName)] seed $($Run.Seed); skipping log copy."
    }

    $LearningAgentsRoot = Join-Path $ProjectDir "Intermediate\LearningAgents"
    $SelectedFolderPath = $null

    if ($TaskName) {
        $Candidate = Join-Path $LearningAgentsRoot $TaskName
        if (Test-Path $Candidate) {
            $SelectedFolderPath = $Candidate
        }
    }

    if (-not $SelectedFolderPath -and (Test-Path $LearningAgentsRoot)) {
        $Candidates = Get-ChildItem -Path $LearningAgentsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if ($TaskName) {
            $Match = $Candidates | Where-Object { $_.Name -like "$TaskName*" } | Select-Object -First 1
            if ($Match) {
                $SelectedFolderPath = $Match.FullName
            }
        }

        if (-not $SelectedFolderPath -and $Candidates) {
            $SelectedFolderPath = $Candidates[0].FullName
        }
    }

    if ($SelectedFolderPath) {
        $TensorSource = Join-Path $SelectedFolderPath "TensorBoard\runs"
        if (Test-Path $TensorSource) {
            $TensorDest = Join-Path $Destinations.TensorBoard $TaskName
            Copy-Item $TensorSource $TensorDest -Recurse -Force
            Write-Host "Copied TensorBoard runs to $TensorDest" -ForegroundColor Green
        } else {
            Write-Warning "TensorBoard runs not found for task $TaskName"
        }

        $NeuralSource = Join-Path $SelectedFolderPath "NeuralNetworks"
        if (Test-Path $NeuralSource) {
            $NeuralDest = Join-Path $Destinations.NeuralNetworks $TaskName
            Copy-Item $NeuralSource $NeuralDest -Recurse -Force
            Write-Host "Copied neural network artifacts to $NeuralDest" -ForegroundColor Green
        } else {
            Write-Warning "Neural network artifacts not found for task $TaskName"
        }

        if ($CleanupIntermediate) {
            try {
                Remove-Item $SelectedFolderPath -Recurse -Force -ErrorAction Stop
                Write-Host "Cleaned up intermediate directory $SelectedFolderPath" -ForegroundColor Gray
            } catch {
                Write-Warning "Failed to clean up intermediate directory ${SelectedFolderPath}: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Warning "Learning Agents output folder not found for task $TaskName"
    }
}

# Define hyperparameter configurations
$ConfigTemplates = @()

if (-not $SkipConservative) {
    $ConfigTemplates += [pscustomobject]@{
        Name        = "Conservative"
        Description = "CONSERVATIVE / LOW LEARNING RATE"
        Seeds       = @()
        Parameters  = [ordered]@{
            LearningRatePolicy = 0.00005
            LearningRateCritic = 0.0005
            EpsilonClip        = 0.1
            PolicyBatchSize    = 512
            CriticBatchSize    = 2048
            IterationsPerGather = 16
            DiscountFactor     = 0.95
            GaeLambda          = 0.9
            ActionEntropyWeight = 0.01
        }
    }
} else {
    Write-Host "Skipping Conservative configuration (SkipConservative flag set)." -ForegroundColor Yellow
}

if (-not $SkipAggressive) {
    $ConfigTemplates += [pscustomobject]@{
        Name        = "Aggressive"
        Description = "AGGRESSIVE / HIGH LEARNING RATE"
        Seeds       = @()
        Parameters  = [ordered]@{
            LearningRatePolicy = 0.0003
            LearningRateCritic = 0.003
            EpsilonClip        = 0.3
            PolicyBatchSize    = 2048
            CriticBatchSize    = 8192
            IterationsPerGather = 64
            DiscountFactor     = 0.995
            GaeLambda          = 0.95
            ActionEntropyWeight = 0.0
        }
    }
} else {
    Write-Host "Skipping Aggressive configuration (SkipAggressive flag set)." -ForegroundColor Yellow
}

if (-not $SkipBalanced) {
    $ConfigTemplates += [pscustomobject]@{
        Name        = "Balanced"
        Description = "BALANCED / MEDIUM LEARNING RATE"
        Seeds       = @()
        Parameters  = [ordered]@{
            LearningRatePolicy = 0.0001
            LearningRateCritic = 0.001
            EpsilonClip        = 0.2
            PolicyBatchSize    = 1024
            CriticBatchSize    = 4096
            IterationsPerGather = 32
            DiscountFactor     = 0.99
            GaeLambda          = 0.95
            ActionEntropyWeight = 0.005
        }
    }
} else {
    Write-Host "Skipping Balanced configuration (SkipBalanced flag set)." -ForegroundColor Yellow
}

if ($ConfigTemplates.Count -eq 0) {
    Write-Warning "No training configurations selected. Nothing to run."
    exit 0
}

$CommonParameters = [ordered]@{
    UseObstacles    = $UseObstacles
    MaxObstacles    = $MaxObstacles
    MinObstacleSize = $MinObstacleSize
    MaxObstacleSize = $MaxObstacleSize
    ObstacleMode    = $ObstacleMode
}

$ConfigDestinations = @{}
$TotalSeedsRequested = 0
foreach ($Config in $ConfigTemplates) {
    $ConfigDestinations[$Config.Name] = Ensure-ConfigDirectories -ConfigName $Config.Name -LogsRoot $LogsDir -TensorBoardRoot $TensorBoardDir -NeuralNetworksRoot $NeuralNetworksDir
    $Config.Seeds = New-RandomSeeds -Count $SeedsPerConfig -Minimum $SeedMinimum -Maximum $SeedMaximum
    $TotalSeedsRequested += $Config.Seeds.Count
    Write-Host "$($Config.Name) -> Generated $($Config.Seeds.Count) random seeds." -ForegroundColor Cyan
}

$Runs = New-Object System.Collections.Generic.List[pscustomobject]

for ($i = 0; $i -lt $SeedsPerConfig; $i++) {
    foreach ($Config in $ConfigTemplates) {
        if ($i -lt $Config.Seeds.Count) {
            $Seed = $Config.Seeds[$i]
            $ParameterSet = [ordered]@{}
            foreach ($Entry in $Config.Parameters.GetEnumerator()) {
                $ParameterSet[$Entry.Key] = $Entry.Value
            }
            foreach ($Entry in $CommonParameters.GetEnumerator()) {
                $ParameterSet[$Entry.Key] = $Entry.Value
            }

            $RunDefinition = [pscustomobject]@{
                ConfigName        = $Config.Name
                ConfigDescription = $Config.Description
                ConfigSafeName    = $ConfigDestinations[$Config.Name].SafeName
                ConfigIndex       = $i + 1
                Seed              = $Seed
                Parameters        = $ParameterSet
            }
            $Runs.Add($RunDefinition)
        }
    }
}

for ($i = 0; $i -lt $Runs.Count; $i++) {
    $Runs[$i] | Add-Member -NotePropertyName Index -NotePropertyValue ($i + 1)
}

$TotalRunsScheduled = $Runs.Count

if ($TotalRunsScheduled -eq 0) {
    Write-Warning "No runs were scheduled after seed generation. Exiting."
    exit 0
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "SPECIAL BATCH PARAMETERS" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Total configurations: $($ConfigTemplates.Count)" -ForegroundColor White
Write-Host "Runs per configuration: $SeedsPerConfig" -ForegroundColor White
Write-Host "Total runs scheduled: $TotalRunsScheduled" -ForegroundColor White
Write-Host "Total random seeds generated: $TotalSeedsRequested" -ForegroundColor White
Write-Host ""

$BatchStartTime = Get-Date

Stop-OrphanedTrainingProcesses

$ConfigStats = @{}
foreach ($Config in $ConfigTemplates) {
    $ConfigStats[$Config.Name] = [ordered]@{
        Scheduled = $Config.Seeds.Count
        Launched  = 0
        Success   = 0
        Timeout   = 0
        Failed    = 0
        Error     = 0
    }
}

$ActiveRuns = [System.Collections.ArrayList]::new()
$RunRecords = [System.Collections.ArrayList]::new()
$NextRunIndex = 0
$StopRequested = $false

Write-Host "Starting batch with up to $ConcurrentRuns concurrent run(s)..." -ForegroundColor Green

while (($NextRunIndex -lt $TotalRunsScheduled -and -not $StopRequested) -or $ActiveRuns.Count -gt 0) {
    while (-not $StopRequested -and $ActiveRuns.Count -lt $ConcurrentRuns -and $NextRunIndex -lt $TotalRunsScheduled) {
        $Run = $Runs[$NextRunIndex]
        $NextRunIndex++

        $ConfigStats[$Run.ConfigName].Launched++

        try {
            $Active = Start-TrainingProcess -Run $Run -ProjectDir $ProjectDir -TrainingBuildDir $TrainingBuildDir -MapName $MapName -ExeName $ExeName -TimeoutMinutes $TimeoutMinutes
            $null = $ActiveRuns.Add($Active)
        } catch {
            Write-Error "Failed to start [$($Run.ConfigName)] seed $($Run.Seed): $($_.Exception.Message)"
            $ConfigStats[$Run.ConfigName].Error++
            $Record = [pscustomobject]@{
                Index          = $Run.Index
                Config         = $Run.ConfigName
                Seed           = $Run.Seed
                TaskName       = $null
                LogFile        = $null
                Status         = "ERROR"
                ExitCode       = $null
                StartTime      = Get-Date
                EndTime        = Get-Date
                Duration       = [TimeSpan]::Zero
                ConfigRunIndex = $Run.ConfigIndex
            }
            $null = $RunRecords.Add($Record)

            if ($StopOnError) {
                Write-Warning "StopOnError enabled. Halting new launches."
                $StopRequested = $true
            }
        }
    }

    if ($ActiveRuns.Count -eq 0) {
        if ($StopRequested -or $NextRunIndex -ge $TotalRunsScheduled) {
            break
        }
        Start-Sleep -Seconds 1
        continue
    }

    Start-Sleep -Seconds 5

    for ($idx = $ActiveRuns.Count - 1; $idx -ge 0; $idx--) {
        $Active = $ActiveRuns[$idx]

        try { $Active.Process.Refresh() } catch {}

        if ($Active.Process.HasExited) {
            $EndTimeRun = Get-Date
            $ExitCode = $null
            try { $ExitCode = $Active.Process.ExitCode } catch { $ExitCode = $null }

            if ($ExitCode -eq 0) {
                $Status = "SUCCESS"
                $ConfigStats[$Active.Run.ConfigName].Success++
            } elseif ($ExitCode -eq -1) {
                $Status = "TIMEOUT"
                $ConfigStats[$Active.Run.ConfigName].Timeout++
            } else {
                $Status = "FAILED"
                $ConfigStats[$Active.Run.ConfigName].Failed++
            }

            $Duration = $EndTimeRun - $Active.StartTime
            Write-Host "Completed [$($Active.Run.ConfigName)] seed $($Active.Run.Seed) -> $Status (ExitCode: $ExitCode)" -ForegroundColor Cyan

            Copy-TrainingArtifacts -ProjectDir $ProjectDir -Run $Active.Run -TaskName $Active.TaskName -LogFileName $Active.LogFile -Destinations $ConfigDestinations[$Active.Run.ConfigName] -Status $Status -CleanupIntermediate:$CleanupIntermediate

            $Record = [pscustomobject]@{
                Index          = $Active.Run.Index
                Config         = $Active.Run.ConfigName
                Seed           = $Active.Run.Seed
                TaskName       = $Active.TaskName
                LogFile        = $Active.LogFile
                Status         = $Status
                ExitCode       = $ExitCode
                StartTime      = $Active.StartTime
                EndTime        = $EndTimeRun
                Duration       = $Duration
                ConfigRunIndex = $Active.Run.ConfigIndex
            }
            $null = $RunRecords.Add($Record)

            $ActiveRuns.RemoveAt($idx)

            if ($Status -eq "FAILED" -and $StopOnError -and -not $StopRequested) {
                Write-Warning "StopOnError enabled. No further runs will be launched."
                $StopRequested = $true
            }
        }
    }
}

if ($ActiveRuns.Count -gt 0) {
    Write-Warning "Batch finished with $($ActiveRuns.Count) run(s) still marked active."
}

$BatchEndTime = Get-Date
$BatchDuration = $BatchEndTime - $BatchStartTime

$SuccessfulRecords = $RunRecords | Where-Object { $_.Status -eq "SUCCESS" }
$TimeoutRecords = $RunRecords | Where-Object { $_.Status -eq "TIMEOUT" }
$FailureRecords = $RunRecords | Where-Object { $_.Status -in @("FAILED", "ERROR") }

$TotalCompleted = $RunRecords.Count
$TotalSuccessLike = $SuccessfulRecords.Count + $TimeoutRecords.Count
$TotalFailures = $FailureRecords.Count

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "BATCH TRAINING SUMMARY" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Runs scheduled: $TotalRunsScheduled" -ForegroundColor White
Write-Host "Runs launched: $($RunRecords.Count)" -ForegroundColor White
Write-Host "Successful: $($SuccessfulRecords.Count)" -ForegroundColor Green
Write-Host "Timeouts: $($TimeoutRecords.Count)" -ForegroundColor Yellow
Write-Host "Failures: $($FailureRecords.Count)" -ForegroundColor Red
Write-Host "Total Duration: $($BatchDuration.ToString("hh\:mm\:ss"))" -ForegroundColor White
Write-Host ""

$SummaryBuilder = New-Object System.Text.StringBuilder
$null = $SummaryBuilder.AppendLine("COOPGAMEFLEEP SPECIAL BATCH TRAINING SUMMARY REPORT")
$null = $SummaryBuilder.AppendLine("==================================================")
$null = $SummaryBuilder.AppendLine("Start Time: $($BatchStartTime.ToString('yyyy-MM-dd HH:mm:ss'))")
$null = $SummaryBuilder.AppendLine("End Time:   $($BatchEndTime.ToString('yyyy-MM-dd HH:mm:ss'))")
$null = $SummaryBuilder.AppendLine("Duration:   $($BatchDuration.ToString('hh\:mm\:ss'))")
$null = $SummaryBuilder.AppendLine("")
$null = $SummaryBuilder.AppendLine("Configured Concurrent Runs: $ConcurrentRuns")
$null = $SummaryBuilder.AppendLine("Seeds per Configuration: $SeedsPerConfig")
$null = $SummaryBuilder.AppendLine("Timeout per Run: $TimeoutMinutes minute(s)")
$null = $SummaryBuilder.AppendLine("Runs Scheduled: $TotalRunsScheduled")
$null = $SummaryBuilder.AppendLine("Runs Launched:  $TotalCompleted")
$null = $SummaryBuilder.AppendLine("Successful:     $($SuccessfulRecords.Count)")
$null = $SummaryBuilder.AppendLine("Timeouts:       $($TimeoutRecords.Count)")
$null = $SummaryBuilder.AppendLine("Failures:       $($FailureRecords.Count)")
$null = $SummaryBuilder.AppendLine("StopOnError:    $StopOnError")
$null = $SummaryBuilder.AppendLine("")
$null = $SummaryBuilder.AppendLine("RESULT DIRECTORY STRUCTURE:")
$null = $SummaryBuilder.AppendLine("  Logs:           $LogsDir")
$null = $SummaryBuilder.AppendLine("  TensorBoard:    $TensorBoardDir")
$null = $SummaryBuilder.AppendLine("  NeuralNetworks: $NeuralNetworksDir")
$null = $SummaryBuilder.AppendLine("")

foreach ($Config in $ConfigTemplates) {
    $Stats = $ConfigStats[$Config.Name]
    $null = $SummaryBuilder.AppendLine("CONFIG: $($Config.Name) - $($Config.Description)")
    $null = $SummaryBuilder.AppendLine("  Seeds Scheduled: $($Stats.Scheduled)")
    $null = $SummaryBuilder.AppendLine("  Launched:        $($Stats.Launched)")
    $null = $SummaryBuilder.AppendLine("  Success:         $($Stats.Success)")
    $null = $SummaryBuilder.AppendLine("  Timeouts:        $($Stats.Timeout)")
    $null = $SummaryBuilder.AppendLine("  Failures:        $($Stats.Failed)")
    $null = $SummaryBuilder.AppendLine("  Errors:          $($Stats.Error)")
    $null = $SummaryBuilder.AppendLine("  Generated Seeds: $([string]::Join(', ', $Config.Seeds))")
    $ConfigRunRecords = $RunRecords | Where-Object { $_.Config -eq $Config.Name } | Sort-Object ConfigRunIndex

    if ($ConfigRunRecords.Count -gt 0) {
        foreach ($Record in $ConfigRunRecords) {
            $null = $SummaryBuilder.AppendLine("    - Iteration $($Record.ConfigRunIndex) | Seed $($Record.Seed) | Status $($Record.Status) | Task $($Record.TaskName) | ExitCode $($Record.ExitCode)")
        }
    } else {
        $null = $SummaryBuilder.AppendLine("    - No runs launched for this configuration.")
    }
    $null = $SummaryBuilder.AppendLine("")
}

$SummaryBuilder.AppendLine("FILES GENERATED:") | Out-Null
$SummaryBuilder.AppendLine("  Logs: $LogsDir") | Out-Null
$SummaryBuilder.AppendLine("  TensorBoard: $TensorBoardDir") | Out-Null
$SummaryBuilder.AppendLine("  Neural Networks: $NeuralNetworksDir") | Out-Null
$SummaryBuilder.AppendLine("  Summary: $SummaryDir") | Out-Null
$SummaryBuilder.AppendLine("") | Out-Null
$SummaryBuilder.AppendLine("NEXT STEPS:") | Out-Null
$SummaryBuilder.AppendLine("1. Inspect log files for anomalies or crashes.") | Out-Null
$SummaryBuilder.AppendLine("2. Launch TensorBoard via ./scripts/run-tensorboard.ps1 --log-dir `"$TensorBoardDir`"") | Out-Null
$SummaryBuilder.AppendLine("3. Compare neural network snapshots across seeds and configurations.") | Out-Null
$SummaryBuilder.AppendLine("4. Aggregate metrics for downstream analysis.") | Out-Null

$SummaryFile = Join-Path $SummaryDir "special_batch_training_summary_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$SummaryBuilder.ToString() | Out-File -FilePath $SummaryFile -Encoding UTF8

Write-Host "Summary report written to: $SummaryFile" -ForegroundColor Cyan
Write-Host "Logs available under:      $LogsDir" -ForegroundColor Cyan
Write-Host "TensorBoard runs:          $TensorBoardDir" -ForegroundColor Cyan
Write-Host "Neural network archives:   $NeuralNetworksDir" -ForegroundColor Cyan
Write-Host ""

if ($TotalFailures -gt 0) {
    Write-Host "Batch completed with failures. Review logs for details." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "All runs completed without failures (timeouts included)." -ForegroundColor Green
    exit 0
}
