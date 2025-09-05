# PowerShell script to package FPSGame for Linux (staged build)
# Usage: .\scripts\package-linux.ps1

param(
    [string]$UnrealPath = "",
    [string]$ProjectPath = (Get-Location).Path,
    [string]$ProjectName = "FPSGame.uproject",
    [string]$Configuration = "Development",
    [string]$ArchiveDirectory = "C:\Builds\FPSGame_Linux"
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

Write-Host "Packaging FPSGame for Linux..." -ForegroundColor Green
Write-Host "Unreal Path: $UnrealPath" -ForegroundColor Yellow
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Project Name: $ProjectName" -ForegroundColor Yellow
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Archive Directory: $ArchiveDirectory" -ForegroundColor Yellow

$RunUATScript = Join-Path $UnrealPath "Engine\Build\BatchFiles\RunUAT.bat"
$ProjectFile = Join-Path $ProjectPath $ProjectName

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

# Create archive directory if it doesn't exist
if (-not (Test-Path $ArchiveDirectory)) {
    Write-Host "Creating archive directory: $ArchiveDirectory" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $ArchiveDirectory -Force | Out-Null
}

Write-Host "Starting Linux packaging process..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow

try {
    & $RunUATScript BuildCookRun `
        -project="$ProjectFile" `
        -noP4 `
        -platform=Linux `
        -cook `
        -build `
        -stage `
        -pak `
        -archive `
        -clientconfig=$Configuration `
        -archivedirectory="$ArchiveDirectory"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Linux packaging completed successfully!" -ForegroundColor Green
        Write-Host "Package location: $ArchiveDirectory\LinuxNoEditor\" -ForegroundColor Cyan
        Write-Host "Ready for deployment to Linux server" -ForegroundColor Cyan
    } else {
        Write-Error "Linux packaging failed with exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} catch {
    Write-Error "Error occurred during Linux packaging: $($_.Exception.Message)"
    exit 1
}

