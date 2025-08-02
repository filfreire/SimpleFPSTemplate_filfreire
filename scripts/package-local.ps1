# Package script for CoopGameFleep project
# Usage: .\scripts\package-local.ps1 [-Target "CoopGameFleep"] [-Platform "Win64"] [-Config "Shipping"] [-OutputDir "Packaged"]

param(
    [string]$UnrealPath = "",
    [string]$ProjectPath = (Get-Location).Path,
    [string]$ProjectName = "CoopGameFleep.uproject",
    [string]$Target = "CoopGameFleep",
    [string]$Platform = "Win64",
    [string]$Config = "Shipping",
    [string]$OutputDir = "Packaged"
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

Write-Host "Packaging CoopGameFleep project..." -ForegroundColor Green
Write-Host "Unreal Path: $UnrealPath" -ForegroundColor Yellow
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Project Name: $ProjectName" -ForegroundColor Yellow
Write-Host "Target: $Target" -ForegroundColor Yellow
Write-Host "Platform: $Platform" -ForegroundColor Yellow
Write-Host "Configuration: $Config" -ForegroundColor Yellow
Write-Host "Output Directory: $OutputDir" -ForegroundColor Yellow

$RunUATScript = Join-Path $UnrealPath "Engine\Build\BatchFiles\RunUAT.bat"
$ProjectFile = Join-Path $ProjectPath $ProjectName
$PackageFolder = Join-Path $ProjectPath $OutputDir

if (-not (Test-Path $RunUATScript)) {
    Write-Error "RunUAT script not found at: $RunUATScript"
    Write-Error "Please check your Unreal Engine installation path"
    exit 1
}

if (-not (Test-Path $ProjectFile)) {
    Write-Error "Project file not found at: $ProjectFile"
    Write-Error "Please check your project path and name"
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path $PackageFolder)) {
    New-Item -ItemType Directory -Path $PackageFolder -Force
    Write-Host "Created output directory: $PackageFolder" -ForegroundColor Cyan
}

Write-Host "Starting packaging process..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow

# Build the RunUAT command arguments
$UATArgs = @(
    "BuildCookRun"
    "-project=`"$ProjectFile`""
    "-nop4"
    "-utf8output"
    "-nocompileeditor"
    "-skipbuildeditor"
    "-cook"
    "-project=`"$ProjectFile`""
    "-target=$Target"
    "-platform=$Platform"
    "-installed"
    "-stage"
    "-archive"
    "-package"
    "-build"
    "-pak"
    "-compressed"
    "-archivedirectory=`"$PackageFolder`""
    "-clientconfig=$Config"
    "-nocompile"
    "-nocompileuat"
    "-nodebuginfo"
)

# Execute the packaging command
& $RunUATScript $UATArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "Packaging completed successfully!" -ForegroundColor Green
    Write-Host "Packaged game location: $PackageFolder" -ForegroundColor Cyan
    
    # Try to find the executable
    $ExeFiles = Get-ChildItem -Path $PackageFolder -Filter "*.exe" -Recurse
    if ($ExeFiles.Count -gt 0) {
        Write-Host "Game executable(s) found:" -ForegroundColor Green
        foreach ($exe in $ExeFiles) {
            Write-Host "  $($exe.FullName)" -ForegroundColor White
        }
    }
} else {
    Write-Error "Packaging failed with exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Press any key to continue..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")