# Build script for FPSGame project
# Usage: .\scripts\build-local.ps1

param(
    [string]$UnrealPath = "",
    [string]$ProjectPath = (Get-Location).Path,
    [string]$ProjectName = "FPSGame.uproject"
)

# Determine UnrealPath based on hostname if not provided
if ([string]::IsNullOrEmpty($UnrealPath)) {
    $hostname = [System.Net.Dns]::GetHostName()
    if ($hostname -eq "filfreire01") {
        $UnrealPath = "C:\unreal\UE_5.6"
    } elseif ($hostname -eq "filfreire02") {
        $UnrealPath = "D:\unreal\UE_5.6"
    } else {
        # Default path if hostname is neither filfreire01 nor filfreire02
        $UnrealPath = "C:\unreal\UE_5.6"
    }
}

Write-Host "Building FPSGame project..." -ForegroundColor Green
Write-Host "Unreal Path: $UnrealPath" -ForegroundColor Yellow
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Project Name: $ProjectName" -ForegroundColor Yellow

$BuildScript = Join-Path $UnrealPath "Engine\Build\BatchFiles\Build.bat"
$ProjectFile = Join-Path $ProjectPath $ProjectName

if (-not (Test-Path $BuildScript)) {
    Write-Error "Build script not found at: $BuildScript"
    Write-Error "Please check your Unreal Engine installation path"
    exit 1
}

if (-not (Test-Path $ProjectFile)) {
    Write-Error "Project file not found at: $ProjectFile"
    Write-Error "Please check your project path and name"
    exit 1
}

Write-Host "Starting build process..." -ForegroundColor Cyan
& $BuildScript FPSGameEditor Win64 Development -Project="$ProjectFile"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build completed successfully!" -ForegroundColor Green
} else {
    Write-Error "Build failed with exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
} 
