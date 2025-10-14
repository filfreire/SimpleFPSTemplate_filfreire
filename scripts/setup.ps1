# Dependency setup script for SimpleFPSTemplate_filfreire project
# Usage: .\scripts\setup.ps1 [-SkipLearningAgents] [-SkipTensorBoard]

param(
    [switch]$SkipLearningAgents = $false,
    [switch]$SkipTensorBoard = $false,
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

    if (-not (Test-Path $ResolvedUnrealPath)) {
        throw "Unreal Engine path not found at '$ResolvedUnrealPath'."
    }

    if (-not (Test-Path $ProjectPath)) {
        throw "Project path not found at '$ProjectPath'."
    }

    $ResolvedProjectPath = (Resolve-Path $ProjectPath).Path
    $ScriptsFolder = Join-Path $ResolvedProjectPath "scripts"

    $LearningAgentsScript = Join-Path $ScriptsFolder "install-learning-agents-deps.ps1"
    $TensorBoardScript = Join-Path $ScriptsFolder "install-tensorboard.ps1"

    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "SimpleFPSTemplate_filfreire - Dependency Setup" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Unreal Path: $ResolvedUnrealPath" -ForegroundColor Yellow
    Write-Host "Project Path: $ResolvedProjectPath" -ForegroundColor Yellow

    if (-not $SkipLearningAgents) {
        if (-not (Test-Path $LearningAgentsScript)) {
            throw "Learning Agents installer not found at '$LearningAgentsScript'."
        }

        Write-Host "\n[1/$(if ($SkipTensorBoard) { '1' } else { '2' })] Installing Learning Agents dependencies..." -ForegroundColor Green
        & $LearningAgentsScript -UnrealPath $ResolvedUnrealPath -ProjectPath $ResolvedProjectPath
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Learning Agents dependency installation failed with exit code $exitCode."
        }
        Write-Host "Learning Agents dependencies installed successfully." -ForegroundColor Green
    }
    else {
        Write-Host "Skipping Learning Agents dependency installation." -ForegroundColor Yellow
    }

    if (-not $SkipTensorBoard) {
        if (-not (Test-Path $TensorBoardScript)) {
            throw "TensorBoard installer not found at '$TensorBoardScript'."
        }

        Write-Host "\n[$(if ($SkipLearningAgents) { '1' } else { '2' })/$(if ($SkipLearningAgents) { '1' } else { '2' })] Installing TensorBoard dependencies..." -ForegroundColor Green
        & $TensorBoardScript -UnrealPath $ResolvedUnrealPath -ProjectPath $ResolvedProjectPath
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "TensorBoard dependency installation failed with exit code $exitCode."
        }
        Write-Host "TensorBoard dependencies installed successfully." -ForegroundColor Green
    }
    else {
        Write-Host "Skipping TensorBoard dependency installation." -ForegroundColor Yellow
    }

    Write-Host "\nDependency setup complete." -ForegroundColor Green
    exit 0
}
catch {
    Write-Error $_
    exit 1
}


