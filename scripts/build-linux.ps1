# PowerShell script to build Linux binary for FPSGame project
# Usage: .\scripts\build-linux.ps1

param(
    [string]$UnrealPath = "",
    [string]$ProjectPath = (Get-Location).Path,
    [string]$ProjectName = "FPSGame.uproject",
    [string]$Configuration = "Development"
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

Write-Host "Building FPSGame for Linux..." -ForegroundColor Green
Write-Host "Unreal Path: $UnrealPath" -ForegroundColor Yellow
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Project Name: $ProjectName" -ForegroundColor Yellow
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow

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

Write-Host "Starting Linux build process..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow

try {
    & $BuildScript FPSGame Linux $Configuration -Project="$ProjectFile" -noclean
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Linux build completed successfully!" -ForegroundColor Green
        Write-Host "Binary location: $ProjectPath\Binaries\Linux\FPSGame-Linux-$Configuration" -ForegroundColor Cyan
        
        # Install Learning Agents dependencies for headless training
        Write-Host "`nInstalling Learning Agents dependencies..." -ForegroundColor Yellow
        try {
            & "$ProjectPath\scripts\install-learning-agents-deps.ps1" -UnrealPath $UnrealPath -ProjectPath $ProjectPath
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Learning Agents dependencies installed successfully!" -ForegroundColor Green
            } else {
                Write-Warning "Learning Agents dependency installation failed, but build completed"
            }
        } catch {
            Write-Warning "Failed to install Learning Agents dependencies: $_"
        }
        
        # Install TensorBoard dependencies
        Write-Host "`nInstalling TensorBoard dependencies..." -ForegroundColor Yellow
        try {
            & "$ProjectPath\scripts\install-tensorboard.ps1" -UnrealPath $UnrealPath -ProjectPath $ProjectPath
            if ($LASTEXITCODE -eq 0) {
                Write-Host "TensorBoard dependencies installed successfully!" -ForegroundColor Green
            } else {
                Write-Warning "TensorBoard dependency installation failed, but build completed"
            }
        } catch {
            Write-Warning "Failed to install TensorBoard dependencies: $_"
        }
    } else {
        Write-Error "Linux build failed with exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} catch {
    Write-Error "Error occurred during Linux build: $($_.Exception.Message)"
    exit 1
}




