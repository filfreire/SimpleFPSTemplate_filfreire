# Troubleshooting

## Unable to find package errors

If you see a handful of errors when you try to run project from VSCode like `Unable to find package (...)`, try to use solution documented in <https://stackoverflow.com/a/70584286>

## Error opening project about bStrictConformanceMode

When converting from Engine version 5.2 to 5.4, I see errors like:

```
modifies the values of properties: [ bStrictConformanceMode ]
```

There's some documentation about it <https://forums.unrealengine.com/t/build-failed-in-unreal-5-4/1789560/9>, editing `CoopGameFleepEditor.Target.cs` and `CoopGameFleep.Target.cs` files with

```
DefaultBuildSettings = BuildSettingsVersion.V5;
bOverrideBuildEnvironment = true;
```

appears to have solved the issue.

## Checking CUDA is properly setup

```powershell
.\Intermediate\PipInstall\Scripts\python.exe -c "import torch; print('CUDA available:', torch.cuda.is_available()); print('CUDA version:', torch.version.cuda if torch.cuda.is_available() else 'N/A')"
```

## Installing clang unreal engine toolchain for Linux cross compilation on Windows

Download `https://cdn.unrealengine.com/CrossToolchain_Linux/v25_clang-18.1.0-rockylinux8.exe`

Install and reboot.

Run `./scripts/build-linux.ps1`

## Disabling UBA when compiling on Linux

Create file `~/.config/Epic/UnrealBuildTool/BuildConfiguration.xml` with contents like:

```xml
<?xml version="1.0" encoding="utf-8" ?>
<Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">
  <BuildConfiguration>
      <bAllowUBAExecutor>false</bAllowUBAExecutor>
      <bAllowUBALocalExecutor>false</bAllowUBALocalExecutor>
  </BuildConfiguration>
</Configuration>
```

### Packaging (Older instructions / CI method):

Run `.\scripts\Package.bat` on a Powershell terminal:

```powershell
# UNREAL_PATH - Unreal engine install path, e.g. C:\Epic Games\UE_5.6
# PROJECT_NAME - project name, e.g. CoopGameFleep.uproject
# TARGET_NAME - name of target, e.g. CoopGameFleep
# PACKAGE_FOLDER - Folder name where to place the packaged game binaries, e.g. PackageResults

.\scripts\Package.bat $env:UNREAL_PATH (Get-Location).Path $env:PROJECT_NAME $env:TARGET_NAME $env:PACKAGE_FOLDER
```

If packaging works successfully, you should see a log like:

```plaintext
UATHelper: Packaging (Windows): ********** ARCHIVE COMMAND COMPLETED **********
UATHelper: Packaging (Windows): BuildCookRun time: 636.56 s
UATHelper: Packaging (Windows): BUILD SUCCESSFUL
UATHelper: Packaging (Windows): AutomationTool executed for 0h 10m 37s
UATHelper: Packaging (Windows): AutomationTool exiting with ExitCode=0 (Success)
```

And you should see a packaged build in `PACKAGE_FOLDER` (or the `-archivedirectory` you've picked in case you edit the `.\scripts\Package.bat` batch file).
