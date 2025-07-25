# Launch Unreal Editor script for FPSGame project
# Usage: .\scripts\ue-editor-local.ps1

param(
    [string]$UnrealPath = "D:\unreal\UE_5.6",
    [string]$ProjectPath = (Get-Location).Path,
    [string]$ProjectName = "FPSGame.uproject"
)

Write-Host "Launching Unreal Editor for FPSGame project..." -ForegroundColor Green
Write-Host "Unreal Path: $UnrealPath" -ForegroundColor Yellow
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Project Name: $ProjectName" -ForegroundColor Yellow

$UnrealEditor = Join-Path $UnrealPath "Engine\Binaries\Win64\UnrealEditor.exe"
$ProjectFile = Join-Path $ProjectPath $ProjectName

if (-not (Test-Path $UnrealEditor)) {
    Write-Error "Unreal Editor not found at: $UnrealEditor"
    Write-Error "Please check your Unreal Engine installation path"
    exit 1
}

if (-not (Test-Path $ProjectFile)) {
    Write-Error "Project file not found at: $ProjectFile"
    Write-Error "Please check your project path and name"
    exit 1
}

Write-Host "Starting Unreal Editor..." -ForegroundColor Cyan
& $UnrealEditor "$ProjectFile"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Unreal Editor launched successfully!" -ForegroundColor Green
} else {
    Write-Error "Failed to launch Unreal Editor with exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
} 
