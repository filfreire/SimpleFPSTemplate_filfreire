# Training Log Monitor for FPSGame
# This script monitors the training logs in real-time
# Usage: .\scripts\tail-training-logs.ps1 [-LogFile "fpscharacter_training.log"] [-Follow] [-Lines 50]

param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$TrainingBuildDir = "TrainingBuild",
    [string]$LogFile = "fpscharacter_training.log",
    [switch]$Follow = $true,
    [int]$Lines = 50,
    [switch]$ShowHelp = $false
)

# Show help if requested
if ($ShowHelp) {
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "FPSGAME TRAINING LOG MONITOR" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\scripts\tail-training-logs.ps1 [options]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -LogFile <name>     Log file to monitor (default: fpscharacter_training.log)" -ForegroundColor White
    Write-Host "  -Follow             Follow the log file (default: true)" -ForegroundColor White
    Write-Host "  -Lines <number>     Number of lines to show initially (default: 50)" -ForegroundColor White
    Write-Host "  -ShowHelp           Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\scripts\tail-training-logs.ps1" -ForegroundColor White
    Write-Host "  .\scripts\tail-training-logs.ps1 -Lines 100" -ForegroundColor White
    Write-Host "  .\scripts\tail-training-logs.ps1 -LogFile 'my_training.log'" -ForegroundColor White
    Write-Host "  .\scripts\tail-training-logs.ps1 -Follow:$false" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    exit 0
}

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "FPSGAME TRAINING LOG MONITOR" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

# Find the log file
$BuildPath = Join-Path $ProjectPath $TrainingBuildDir
$LogFiles = Get-ChildItem -Path $BuildPath -Filter $LogFile -Recurse

if ($LogFiles.Count -eq 0) {
    Write-Error "Log file '$LogFile' not found in build directory: $BuildPath"
    Write-Error "Available log files:"
    $AllLogs = Get-ChildItem -Path $BuildPath -Filter "*.log" -Recurse
    foreach ($log in $AllLogs) {
        Write-Host "  $($log.FullName)" -ForegroundColor Gray
    }
    Write-Error "Please check the TrainingBuild directory or specify the correct log file name"
    exit 1
}

$LogFilePath = $LogFiles[0].FullName
Write-Host "Monitoring log file: $LogFilePath" -ForegroundColor Yellow
Write-Host "Lines to show: $Lines" -ForegroundColor Yellow
Write-Host "Follow mode: $Follow" -ForegroundColor Yellow
Write-Host ""

# Check if log file exists and has content
if (-not (Test-Path $LogFilePath)) {
    Write-Error "Log file does not exist: $LogFilePath"
    exit 1
}

$LogSize = (Get-Item $LogFilePath).Length
if ($LogSize -eq 0) {
    Write-Warning "Log file is empty. Waiting for content..."
    Write-Host "Press Ctrl+C to stop waiting" -ForegroundColor Yellow
    Write-Host ""
}

# Show recent log entries
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "RECENT LOG ENTRIES" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

try {
    if ($Follow) {
        # Show last N lines and then follow
        Get-Content -Path $LogFilePath -Tail $Lines -Wait
    } else {
        # Just show last N lines
        Get-Content -Path $LogFilePath -Tail $Lines
    }
}
catch {
    if ($_.Exception.Message -like "*being used by another process*") {
        Write-Error "Log file is being used by another process. Try again in a moment."
    } else {
        Write-Error "Error reading log file: $($_.Exception.Message)"
    }
    exit 1
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "LOG MONITORING ENDED" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan
