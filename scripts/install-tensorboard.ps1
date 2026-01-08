# PowerShell script to install TensorBoard into Unreal Engine's Python environment

param(
    [string]$UnrealPath = "",
    [string]$ProjectPath = (Get-Location).Path
)

function Resolve-UnrealPath {
    param([string]$PathFromArgs)

    if (-not [string]::IsNullOrEmpty($PathFromArgs)) {
        return $PathFromArgs
    }

    $hostname = [System.Net.Dns]::GetHostName()
    switch -Regex ($hostname.ToLowerInvariant()) {
        "^filfreire01$" { return "C:\\unreal\\UE_5.6" }
        "^filfreire02$" { return "D:\\unreal\\UE_5.6" }
        "^desktop-doap6m9$" { return "E:\\unreal\\UE_5.6" }
        "^unreal-" { return "C:\\unreal\\UE_5.6" }
        default { return "D:\\unreal\\UE_5.6" }
    }
}

try {
    $ResolvedUnrealPath = Resolve-UnrealPath -PathFromArgs $UnrealPath
    
    # Use Unreal's Python, not the project's local Python
    $pythonPath = Join-Path $ResolvedUnrealPath "Engine\Binaries\ThirdParty\Python3\Win64\python.exe"

    # Check if the Python executable exists
    if (Test-Path $pythonPath) {
        Write-Host "Found Unreal Engine's Python executable at: $pythonPath" -ForegroundColor Green
        
        # Install TensorBoard using Unreal's Python
        Write-Host "Installing TensorBoard into Unreal Engine's Python environment..." -ForegroundColor Yellow
        
        & $pythonPath -m pip install tensorboard torch numpy
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "TensorBoard installed successfully!" -ForegroundColor Green
            exit 0
        } else {
            Write-Host "Failed to install TensorBoard. Exit code: $LASTEXITCODE" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Unreal Engine's Python executable not found at: $pythonPath" -ForegroundColor Red
        Write-Host "Please verify your Unreal Engine installation path." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "Error occurred while installing TensorBoard: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
