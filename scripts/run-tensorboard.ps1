# PowerShell script to run TensorBoard using Unreal's pip-installed Python

# Define the path to the Python executable
$pythonPath = "Intermediate\PipInstall\Scripts\python.exe"

# Define the TensorBoard log directory
$logDir = "Intermediate\LearningAgents\TensorBoard\runs"

# Check if the Python executable exists
if (Test-Path $pythonPath) {
    Write-Host "Found Python executable at: $pythonPath" -ForegroundColor Green
    
    # Check if the log directory exists
    if (Test-Path $logDir) {
        Write-Host "Found TensorBoard logs at: $logDir" -ForegroundColor Green
        
        # Run TensorBoard using the found Python executable
        Write-Host "Starting TensorBoard for SimpleFPSTemplate..." -ForegroundColor Yellow
        Write-Host "TensorBoard will be available at: http://localhost:6007" -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop TensorBoard" -ForegroundColor Yellow
        
        try {
            & $pythonPath -m tensorboard --logdir=$logDir --port=6007
        }
        catch {
            Write-Host "Error occurred while running TensorBoard: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "TensorBoard log directory not found at: $logDir" -ForegroundColor Red
        Write-Host "Make sure you have run Learning Agents training to generate logs." -ForegroundColor Yellow
        Write-Host "The log directory will be created automatically when training starts." -ForegroundColor Yellow
    }
} else {
    Write-Host "Python executable not found at: $pythonPath" -ForegroundColor Red
    Write-Host "Make sure you have the Learning Agents plugin enabled and Python dependencies installed." -ForegroundColor Yellow
    Write-Host "You may need to build your project first to generate the Python environment." -ForegroundColor Yellow
    Write-Host "Also run install-tensorboard.ps1 to install TensorBoard." -ForegroundColor Yellow
}

# Pause to see the output if TensorBoard exits
Write-Host "Press any key to continue..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
