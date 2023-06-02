# SimpleFPSTemplate

[![build workflow status](https://github.com/filfreire/SimpleFPSTemplate_filfreire/actions/workflows/build.yml/badge.svg)](https://github.com/filfreire/SimpleFPSTemplate_filfreire/actions/workflows/build.yml)

Simple C++ FPS Template for Unreal Engine 4. This fork is adapted from <https://github.com/tomlooman/SimpleFPSTemplate>.

## Prerequisites

For Windows 10/11:

- Install [Unreal Engine 4.27](https://www.unrealengine.com/en-US/download) (and all needed sub-dependencies)
- Install [Visual Studio 2022](https://visualstudio.microsoft.com/vs/)
- Install all dependencies mentioned on [official documentation](https://docs.unrealengine.com/4.27/en-US/setting-up-visual-studio-development-environment-for-cplusplus-projects-in-unreal-engine/)

(Tested on a Windows 10 Pro, version 22H2)

## How to build

First, clone the repository, make sure you have everything listed on **Prerequisites** setup and then `cd` into the cloned folder.

Use `.\scripts\Build.bat` batch file to compile/build the project:

```powershell
# UNREAL_PATH - Unreal engine install path, e.g. C:\Epic Games\UE_4.27
# PROJECT_NAME - project name, e.g. FPSGame.uproject

.\scripts\Build.bat $env:UNREAL_PATH (Get-Location).Path $env:PROJECT_NAME
```

## How to run tests

To run tests, use the `.\scripts\RunTests.bat` batch file:

```powershell
# UNREAL_PATH - Unreal engine install path, e.g. C:\Epic Games\UE_4.27
# PROJECT_NAME - project name, e.g. FPSGame.uproject
# TEST_SUITE_TO_RUN - e.g. FPSGameTests.
# TEST_REPORT_FOLDER - e.g. TestResults
# TEST_LOGNAME - e.g. RunTests.log
# UNREAL_EDITOR_CMD - UE4Editor-Cmd.exe (Unreal 4) UnrealEditor-Cmd.exe (Unreal 5)

.\scripts\RunTests.bat $env:UNREAL_PATH (Get-Location).Path $env:PROJECT_NAME $env:TEST_SUITE_TO_RUN $env:TEST_REPORT_FOLDER $env:TEST_LOGNAME
```

## How to package and run

To package a game build for Win64 platform, r   un `.\scripts\Package.bat` on a Powershell terminal:

```powershell
# UNREAL_PATH - Unreal engine install path, e.g. C:\Epic Games\UE_4.27
# PROJECT_NAME - project name, e.g. FPSGame.uproject
# TARGET_NAME - name of target, e.g. FPSGame
# PACKAGE_FOLDER - Folder name where to place the packaged game binaries, e.g. PackageResults

.\scripts\Package.bat $env:UNREAL_PATH (Get-Location).Path $env:PROJECT_NAME $env:TARGET_NAME $env:PACKAGE_FOLDER
```
