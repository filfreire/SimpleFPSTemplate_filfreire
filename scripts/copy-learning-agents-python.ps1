# Copy LearningAgents Python Content to Training Build
# This script copies the LearningAgents Python content from the Engine to the packaged build
# so that headless training can find the required Python files

param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$TrainingBuildDir = "TrainingBuild",
    [string]$UnrealPath = ""
)

# Determine UnrealPath based on hostname if not provided
if ([string]::IsNullOrEmpty($UnrealPath)) {
    $hostname = [System.Net.Dns]::GetHostName()
    if ($hostname -eq "filfreire01") {
        $UnrealPath = "C:\unreal\UE_5.6"
    } elseif ($hostname -eq "desktop-doap6m9") {
        $UnrealPath = "E:\unreal\UE_5.6"
    } else {
        # Default path if hostname is neither filfreire01 nor desktop-doap6m9
        $UnrealPath = "C:\unreal\UE_5.6"
    }
}

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "COPYING LEARNING AGENTS PYTHON CONTENT" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Training Build Dir: $TrainingBuildDir" -ForegroundColor Yellow
Write-Host "Unreal Path: $UnrealPath" -ForegroundColor Yellow

# Source and destination paths
$SourcePath = Join-Path $UnrealPath "Engine\Plugins\Experimental\LearningAgents\Content\Python"
$DestPath = Join-Path $ProjectPath "$TrainingBuildDir\Windows\Engine\Plugins\Experimental\LearningAgents\Content\Python"

Write-Host "`nSource Path: $SourcePath" -ForegroundColor White
Write-Host "Destination Path: $DestPath" -ForegroundColor White

# Check if source exists
if (-not (Test-Path $SourcePath)) {
    Write-Error "Source path does not exist: $SourcePath"
    Write-Error "Please check your Unreal Engine installation path"
    exit 1
}

# Create destination directory structure
$DestDir = Split-Path $DestPath -Parent
if (-not (Test-Path $DestDir)) {
    Write-Host "Creating destination directory: $DestDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

# Copy the Python content
Write-Host "`nCopying LearningAgents Python content..." -ForegroundColor Yellow
try {
    Copy-Item -Path $SourcePath -Destination $DestPath -Recurse -Force
    Write-Host "Successfully copied LearningAgents Python content!" -ForegroundColor Green
} catch {
    Write-Error "Failed to copy LearningAgents Python content: $_"
    exit 1
}

# Verify the copy
if (Test-Path $DestPath) {
    $FileCount = (Get-ChildItem -Path $DestPath -Recurse -File).Count
    Write-Host "Verification: $FileCount files copied to destination" -ForegroundColor Green
} else {
    Write-Error "Copy verification failed - destination path does not exist"
    exit 1
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "COPY COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "LearningAgents Python content is now available for headless training." -ForegroundColor White

