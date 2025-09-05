# PowerShell script to deploy FPSGame to Linux server
# Usage: .\scripts\deploy-linux.ps1

param(
    [string]$LinuxUser = "",
    [string]$LinuxHost = "",
    [string]$LinuxPath = "/home/user/FPSGame",
    [string]$ArchiveDirectory = "C:\Builds\FPSGame_Linux",
    [string]$MapName = "ThirdPersonExampleMap"
)

Write-Host "Deploying FPSGame to Linux server..." -ForegroundColor Green

# Check if required parameters are provided
if ([string]::IsNullOrEmpty($LinuxUser) -or [string]::IsNullOrEmpty($LinuxHost)) {
    Write-Host "Usage: .\scripts\deploy-linux.ps1 -LinuxUser <username> -LinuxHost <hostname_or_ip>" -ForegroundColor Yellow
    Write-Host "Optional parameters:" -ForegroundColor Yellow
    Write-Host "  -LinuxPath: Remote path on Linux server (default: /home/user/FPSGame)" -ForegroundColor Yellow
    Write-Host "  -ArchiveDirectory: Local package directory (default: C:\Builds\FPSGame_Linux)" -ForegroundColor Yellow
    Write-Host "  -MapName: Map to load (default: ThirdPersonExampleMap)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Cyan
    Write-Host "  .\scripts\deploy-linux.ps1 -LinuxUser ubuntu -LinuxHost 192.168.1.100" -ForegroundColor Cyan
    exit 1
}

$PackagePath = Join-Path $ArchiveDirectory "LinuxNoEditor"

if (-not (Test-Path $PackagePath)) {
    Write-Error "Package not found at: $PackagePath"
    Write-Error "Please run package-linux.ps1 first to create the Linux package"
    exit 1
}

Write-Host "Package found at: $PackagePath" -ForegroundColor Green
Write-Host "Deploying to: $LinuxUser@$LinuxHost:$LinuxPath" -ForegroundColor Yellow

# Create deployment commands
$DeployCommand = "scp -r `"$PackagePath`" $LinuxUser@$LinuxHost`:$LinuxPath"

Write-Host "Deployment command:" -ForegroundColor Cyan
Write-Host $DeployCommand -ForegroundColor White

Write-Host ""
Write-Host "After deployment, run these commands on your Linux server:" -ForegroundColor Yellow
Write-Host "1. Install required libraries:" -ForegroundColor Cyan
Write-Host "   sudo apt-get update" -ForegroundColor White
Write-Host "   sudo apt-get install -y libcurl4 zlib1g libicu-dev libssl3 libuuid1 libncurses5 libtinfo5 libstdc++6" -ForegroundColor White
Write-Host ""
Write-Host "2. Make the binary executable:" -ForegroundColor Cyan
Write-Host "   cd $LinuxPath/LinuxNoEditor" -ForegroundColor White
Write-Host "   chmod +x ./FPSGame-Linux-Development" -ForegroundColor White
Write-Host ""
Write-Host "3. Run the game headless:" -ForegroundColor Cyan
Write-Host "   ./FPSGame-Linux-Development -nullrhi -nosound -unattended -log -Execcmds=`"open /Game/Maps/$MapName`"" -ForegroundColor White
Write-Host ""
Write-Host "4. Check logs for success:" -ForegroundColor Cyan
Write-Host "   Look for: LogInit: Build: ... and LogWorld: Bringing up level for play took ..." -ForegroundColor White

Write-Host ""
Write-Host "Press Enter to start deployment, or Ctrl+C to cancel..." -ForegroundColor Yellow
Read-Host

try {
    Write-Host "Starting deployment..." -ForegroundColor Cyan
    Invoke-Expression $DeployCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        Write-Host "Follow the Linux server setup instructions above to run the game" -ForegroundColor Cyan
    } else {
        Write-Error "Deployment failed with exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} catch {
    Write-Error "Error occurred during deployment: $($_.Exception.Message)"
    exit 1
}

