# PowerShell script to setup Linux toolchain for cross-compilation
# Usage: .\scripts\setup-linux-toolchain.ps1

param(
    [string]$UnrealPath = ""
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

Write-Host "Setting up Linux toolchain for cross-compilation..." -ForegroundColor Green
Write-Host "Unreal Path: $UnrealPath" -ForegroundColor Yellow

$SetupScript = Join-Path $UnrealPath "Engine\Extras\ThirdPartyNotUE\SDKs\HostLinux\Linux_x64\LinuxToolchain\Setup.bat"

if (-not (Test-Path $SetupScript)) {
    Write-Error "Linux toolchain setup script not found at: $SetupScript"
    Write-Error "Please check your Unreal Engine installation path"
    Write-Error "Make sure you have the Linux toolchain components installed"
    exit 1
}

Write-Host "Running Linux toolchain setup..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow

try {
    & $SetupScript
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Linux toolchain setup completed successfully!" -ForegroundColor Green
        Write-Host "You can now build Linux binaries from Windows" -ForegroundColor Cyan
    } else {
        Write-Error "Linux toolchain setup failed with exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} catch {
    Write-Error "Error occurred while setting up Linux toolchain: $($_.Exception.Message)"
    exit 1
}

