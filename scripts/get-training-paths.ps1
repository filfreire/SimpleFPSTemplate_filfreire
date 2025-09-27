# Get Training Paths for Existing Build
# This script calculates the relative paths needed for Learning Agents headless training
# from an existing packaged build

param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$UnrealPath = "",
    [string]$BuildPath = "TrainingBuild\Windows\FPSGame\Binaries\Win64"
)

# Determine UnrealPath based on hostname if not provided
if ([string]::IsNullOrEmpty($UnrealPath)) {
    $hostname = [System.Net.Dns]::GetHostName()
    if ($hostname -eq "filfreire01") {
        $UnrealPath = "C:\unreal\UE_5.6"
    } elseif ($hostname -eq "filfreire02") {
        $UnrealPath = "D:\unreal\UE_5.6"
    } elseif ($hostname -eq "desktop-doap6m9") {
        $UnrealPath = "E:\unreal\UE_5.6"
    } elseif ($hostname -like "unreal-*") {
        $UnrealPath = "c:\unreal\UE_5.6"
    } else {
        # Default path if hostname doesn't match known patterns
        $UnrealPath = "D:\unreal\UE_5.6"
    }
}

# Helper function to calculate relative path (compatible with older PowerShell versions)
function Get-RelativePath {
    param([string]$FromPath, [string]$ToPath)
    
    $FromPathNormalized = (Resolve-Path $FromPath).Path.TrimEnd('\')
    $ToPathNormalized = (Resolve-Path $ToPath).Path.TrimEnd('\')
    
    # Split paths into components
    $FromParts = $FromPathNormalized.Split('\')
    $ToParts = $ToPathNormalized.Split('\')
    
    # Find common root
    $CommonLength = 0
    $MinLength = [Math]::Min($FromParts.Length, $ToParts.Length)
    
    for ($i = 0; $i -lt $MinLength; $i++) {
        if ($FromParts[$i] -eq $ToParts[$i]) {
            $CommonLength++
        } else {
            break
        }
    }
    
    # Calculate relative path
    $UpLevels = $FromParts.Length - $CommonLength
    $RelativeParts = @()
    
    # Add ".." for each level up
    for ($i = 0; $i -lt $UpLevels; $i++) {
        $RelativeParts += ".."
    }
    
    # Add remaining path components
    for ($i = $CommonLength; $i -lt $ToParts.Length; $i++) {
        $RelativeParts += $ToParts[$i]
    }
    
    $RelativePath = $RelativeParts -join '/'
    return $RelativePath
}

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "LEARNING AGENTS PATH CALCULATOR" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

$ExePath = Join-Path $ProjectPath $BuildPath

# Check if the build exists
if (-not (Test-Path $ExePath)) {
    Write-Error "Build not found at: $ExePath"
    Write-Host "Available builds:" -ForegroundColor Yellow
    if (Test-Path "TrainingBuild") {
        Write-Host "  - TrainingBuild (Development build - RECOMMENDED for training)" -ForegroundColor Green
    }
    if (Test-Path "Packaged") {
        Write-Host "  - Packaged (Shipping build - not recommended for training)" -ForegroundColor Yellow
    }
    exit 1
}

# Check if Unreal Engine path exists
if (-not (Test-Path $UnrealPath)) {
    Write-Error "Unreal Engine not found at: $UnrealPath"
    Write-Host "Please check your Unreal Engine installation path" -ForegroundColor Yellow
    exit 1
}

Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Unreal Engine Path: $UnrealPath" -ForegroundColor Yellow
Write-Host "Build Path: $ExePath" -ForegroundColor Yellow

# Calculate relative paths
$RelativeToEngine = Get-RelativePath -FromPath $ExePath -ToPath (Join-Path $UnrealPath "Engine")
$RelativeToIntermediate = Get-RelativePath -FromPath $ExePath -ToPath (Join-Path $ProjectPath "Intermediate")

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "LEARNING AGENTS TRAINER SETTINGS" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "`nCopy these paths to your Learning Agents Trainer settings:" -ForegroundColor Green

Write-Host "`nNon Editor Engine Relative Path:" -ForegroundColor Cyan
Write-Host "  $RelativeToEngine" -ForegroundColor White

Write-Host "`nNon Editor Intermediate Relative Path:" -ForegroundColor Cyan
Write-Host "  $RelativeToIntermediate" -ForegroundColor White

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "HOW TO USE THESE PATHS:" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "`n1. Open your FPSCharacterManager blueprint in Unreal Editor" -ForegroundColor White
Write-Host "2. Set Run Mode to 'Training'" -ForegroundColor White
Write-Host "3. In Trainer Training Settings:" -ForegroundColor White
Write-Host "   - Enable Use Tensorboard = True" -ForegroundColor White
Write-Host "   - Enable Save Snapshots = True" -ForegroundColor White
Write-Host "4. In Trainer Path Settings:" -ForegroundColor White
Write-Host "   - Set Non Editor Engine Relative Path to: $RelativeToEngine" -ForegroundColor Green
Write-Host "   - Set Non Editor Intermediate Relative Path to: $RelativeToIntermediate" -ForegroundColor Green
Write-Host "5. Save the blueprint and start headless training" -ForegroundColor White

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "READY FOR HEADLESS TRAINING!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

