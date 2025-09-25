# Install Learning Agents Python Dependencies using UBT PipInstall Mode
# This script uses Unreal Engine's built-in Pip Installer to install dependencies
# exactly like the Editor GUI does automatically
# Usage: .\scripts\install-learning-agents-deps.ps1

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

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "INSTALLING LEARNING AGENTS DEPENDENCIES" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Unreal Path: $UnrealPath" -ForegroundColor Yellow
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Project Name: $ProjectName" -ForegroundColor Yellow

# Paths
$BuildScript = Join-Path $UnrealPath "Engine\Build\BatchFiles\Build.bat"
$ProjectFile = Join-Path $ProjectPath $ProjectName
$PipInstallPath = Join-Path $ProjectPath "Intermediate\PipInstall"

# Check if Build script exists
if (-not (Test-Path $BuildScript)) {
    Write-Error "Build script not found at: $BuildScript"
    Write-Error "Please check your Unreal Engine installation path"
    exit 1
}

# Check if project file exists
if (-not (Test-Path $ProjectFile)) {
    Write-Error "Project file not found at: $ProjectFile"
    Write-Error "Please check your project path and name"
    exit 1
}

# Check if PipInstall already exists and is not empty
if (Test-Path $PipInstallPath) {
    $PythonExe = Join-Path $PipInstallPath "Scripts\python.exe"
    if (Test-Path $PythonExe) {
        Write-Host "PipInstall directory already exists with Python executable" -ForegroundColor Yellow
        Write-Host "Skipping installation..." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`nRunning UBT PipInstall mode..." -ForegroundColor Yellow
Write-Host "This will install Python dependencies exactly like the Editor GUI does" -ForegroundColor Gray

# Run UBT with PipInstall mode
$BuildArgs = @(
    "FPSGameEditor"
    "Win64"
    "Development"
    "-Project=`"$ProjectFile`""
    "-Mode=PipInstall"
)

Write-Host "Executing: $BuildScript $($BuildArgs -join ' ')" -ForegroundColor Gray
& $BuildScript $BuildArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ PipInstall completed successfully!" -ForegroundColor Green
    
    # Verify installation
    $PythonExe = Join-Path $PipInstallPath "Scripts\python.exe"
    if (Test-Path $PythonExe) {
        Write-Host "`nVerifying installation..." -ForegroundColor Yellow
        & $PythonExe -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available())"
        & $PythonExe -c "import tensorboard; print('TensorBoard version:', tensorboard.__version__)"
        & $PythonExe -c "import numpy; print('NumPy version:', numpy.__version__)"
        Write-Host "✓ Core dependencies verified successfully" -ForegroundColor Green
    }
} else {
    Write-Error "PipInstall failed with exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "INSTALLATION COMPLETED!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Learning Agents Python dependencies are now available at:" -ForegroundColor White
Write-Host "  $PipInstallPath" -ForegroundColor Gray
Write-Host "`nPython executable:" -ForegroundColor White
Write-Host "  $PythonExe" -ForegroundColor Gray
Write-Host "`nYou can now run headless training without opening the Unreal Editor!" -ForegroundColor Green