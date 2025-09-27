# PowerShell script to install TensorBoard using Unreal's pip-installed Python

# Define the path to the Python executable
$pythonPath = "Intermediate\PipInstall\Scripts\python.exe"

# Check if the Python executable exists
if (Test-Path $pythonPath) {
    Write-Host "Found Python executable at: $pythonPath" -ForegroundColor Green
    
    # Install TensorBoard using the found Python executable
    Write-Host "Installing TensorBoard..." -ForegroundColor Yellow
    
    try {
        & $pythonPath -m pip install tensorboard
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "TensorBoard installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Failed to install TensorBoard. Exit code: $LASTEXITCODE" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error occurred while installing TensorBoard: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Python executable not found at: $pythonPath" -ForegroundColor Red
    Write-Host "Make sure you have the Learning Agents plugin enabled and Python dependencies installed." -ForegroundColor Yellow
    Write-Host "You may need to build your project first to generate the Python environment." -ForegroundColor Yellow
}
