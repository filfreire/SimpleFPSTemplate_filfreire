# Unified packaging script for FPSGame project
# Usage: .\scripts\package.ps1 [-Mode Training|Shipping] [-SkipSetup]

param(
    [ValidateSet("Training", "Shipping")]
    [string]$Mode = "Training",
    [switch]$SkipSetup = $false,
    [string]$UnrealPath = "",
    [string]$ProjectPath = (Get-Location).Path,
    [string]$ProjectName = "FPSGame.uproject",
    [string]$Target = "FPSGame",
    [string]$Platform = "Win64",
    [string]$OutputDir = ""
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

function Test-PathExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if (-not (Test-Path $Path)) {
        throw "${Description} not found at '$Path'."
    }
}

try {
    $ResolvedUnrealPath = Resolve-UnrealPath -PathFromArgs $UnrealPath
    Test-PathExists -Path $ResolvedUnrealPath -Description "Unreal Engine path"
    Test-PathExists -Path $ProjectPath -Description "Project path"

    $ResolvedProjectPath = (Resolve-Path $ProjectPath).Path
    $ProjectFile = Join-Path $ResolvedProjectPath $ProjectName
    Test-PathExists -Path $ProjectFile -Description "Project file"

    $RunUATScript = Join-Path $ResolvedUnrealPath "Engine/Build/BatchFiles/RunUAT.bat"
    Test-PathExists -Path $RunUATScript -Description "RunUAT script"

    $buildConfiguration = if ($Mode -eq "Training") { "Development" } else { "Shipping" }
    if ([string]::IsNullOrEmpty($OutputDir)) {
        $OutputDir = if ($Mode -eq "Training") { "TrainingBuild" } else { "Packaged" }
    }

    $PackageFolder = Join-Path $ResolvedProjectPath $OutputDir
    if (-not (Test-Path $PackageFolder)) {
        New-Item -ItemType Directory -Path $PackageFolder -Force | Out-Null
    }

    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "FPSGame - ${Mode} Package" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Unreal Path: $ResolvedUnrealPath" -ForegroundColor Yellow
    Write-Host "Project Path: $ResolvedProjectPath" -ForegroundColor Yellow
    Write-Host "Project File: $ProjectFile" -ForegroundColor Yellow
    Write-Host "Target: $Target" -ForegroundColor Yellow
    Write-Host "Platform: $Platform" -ForegroundColor Yellow
    Write-Host "Configuration: $buildConfiguration" -ForegroundColor Yellow
    Write-Host "Output Directory: $PackageFolder" -ForegroundColor Yellow

    # Step 1: Build required targets once each
    Write-Host "\n[1/3] Building code..." -ForegroundColor Green

    $buildScriptPath = Join-Path $PSScriptRoot "build.ps1"
    $buildTargets = @(
        [pscustomobject]@{ Target = "FPSGameEditor"; Configuration = "Development" },
        [pscustomobject]@{ Target = $Target; Configuration = $buildConfiguration }
    ) | Where-Object { -not [string]::IsNullOrEmpty($_.Target) -and -not [string]::IsNullOrEmpty($_.Configuration) }

    $uniqueBuildTargets = $buildTargets | Sort-Object Target, Configuration -Unique
    $buildIndex = 1
    foreach ($entry in $uniqueBuildTargets) {
        Write-Host "  - [$buildIndex/$($uniqueBuildTargets.Count)] $($entry.Target) ($($entry.Configuration))" -ForegroundColor Yellow
        & $buildScriptPath -UnrealPath $ResolvedUnrealPath -ProjectPath $ResolvedProjectPath -ProjectName $ProjectName -Target $entry.Target -Platform $Platform -Configuration $entry.Configuration
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Build step failed for target '$($entry.Target)' with exit code $exitCode."
        }
        $buildIndex++
    }

    # Step 2: Setup dependencies (optional)
    if (-not $SkipSetup) {
        Write-Host "\n[2/3] Installing dependencies..." -ForegroundColor Green
        & (Join-Path $PSScriptRoot "setup.ps1") -UnrealPath $ResolvedUnrealPath -ProjectPath $ResolvedProjectPath
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Dependency setup failed with exit code $exitCode."
        }
    }
    else {
        Write-Host "\n[2/3] Skipping dependency setup." -ForegroundColor Yellow
    }

    # Step 3: Package build once
    Write-Host "\n[3/3] Packaging project..." -ForegroundColor Green

    $UATArgs = @(
        "BuildCookRun",
        "-project=`"$ProjectFile`"",
        "-nop4",
        "-utf8output",
        "-nocompileeditor",
        "-skipbuildeditor",
        "-target=$Target",
        "-platform=$Platform",
        "-stage",
        "-archive",
        "-package",
        "-pak",
        "-compressed",
        "-archivedirectory=`"$PackageFolder`"",
        "-clientconfig=$buildConfiguration",
        "-nocompile",
        "-nocompileuat",
        "-installed"
    )

    if ($Mode -eq "Training") {
        $UATArgs += "-cook"
    }
    else {
        $UATArgs += "-nodebuginfo"
        $UATArgs += "-cook"
    }

    Write-Host "Executing: $RunUATScript $($UATArgs -join ' ')" -ForegroundColor DarkGray
    & $RunUATScript $UATArgs
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Packaging failed with exit code $exitCode."
    }

    Write-Host "\nPackaging completed successfully." -ForegroundColor Green

    $ExeFiles = Get-ChildItem -Path $PackageFolder -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
    if ($ExeFiles.Count -gt 0) {
        Write-Host "Executable(s) located:" -ForegroundColor Cyan
        foreach ($exe in $ExeFiles) {
            Write-Host "  $($exe.FullName)" -ForegroundColor White
        }
    }

    exit 0
}
catch {
    Write-Error $_
    exit 1
}
