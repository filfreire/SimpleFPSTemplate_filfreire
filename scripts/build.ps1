# Build-only script for SimpleFPSTemplate_filfreire project
# Usage: .\scripts\build.ps1 [-UnrealPath "C:\\unreal\\UE_5.6"] [-ProjectPath "D:\\unrealprojects\\SimpleFPSTemplate_filfreire"] [-ProjectName "FPSGame.uproject"]

param(
    [string]$UnrealPath = "",
    [string]$ProjectPath = (Get-Location).Path,
    [string]$ProjectName = "FPSGame.uproject",
    [string]$Target = "FPSGameEditor",
    [string]$Platform = "Win64",
    [string]$Configuration = "Development"
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
    $ProjectFile = Join-Path $ResolvedProjectPath $ProjectName

    if (-not (Test-Path $ProjectFile)) {
        throw "Project file not found at '$ProjectFile'."
    }

    $BuildScript = Join-Path $ResolvedUnrealPath "Engine/Build/BatchFiles/Build.bat"

    if (-not (Test-Path $BuildScript)) {
        throw "Build script not found at '$BuildScript'."
    }

    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "SimpleFPSTemplate_filfreire - Code Build" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Unreal Path: $ResolvedUnrealPath" -ForegroundColor Yellow
    Write-Host "Project Path: $ResolvedProjectPath" -ForegroundColor Yellow
    Write-Host "Target: $Target" -ForegroundColor Yellow
    Write-Host "Platform: $Platform" -ForegroundColor Yellow
    Write-Host "Configuration: $Configuration" -ForegroundColor Yellow

    $BuildArgs = @(
        $Target,
        $Platform,
        $Configuration,
        "-Project=`"$ProjectFile`"",
        "-WaitMutex"
    )

    Write-Host "\nStarting build..." -ForegroundColor Cyan
    & $BuildScript $BuildArgs
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "Build failed with exit code $exitCode."
    }

    Write-Host "\nBuild completed successfully." -ForegroundColor Green
    exit 0
}
catch {
    Write-Error $_
    exit 1
}

