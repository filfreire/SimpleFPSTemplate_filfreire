# SimpleFPSTemplate

[![build workflow status](https://github.com/filfreire/SimpleFPSTemplate_filfreire/actions/workflows/build.yml/badge.svg)](https://github.com/filfreire/SimpleFPSTemplate_filfreire/actions/workflows/build.yml)

Simple C++ FPS Template for Unreal Engine 4. This fork is my personal repo with exercises, experiments and classwork (for <https://www.udemy.com/course/unrealengine-cpp>) and is adapted from <https://github.com/tomlooman/SimpleFPSTemplate>.

> Note: this repository is in a WIP state.

## Prerequisites

For Windows 10/11:

- Install [Epic Games Launcher](https://store.epicgames.com/en-US/download)
- Install [Unreal Engine 5.6.1](https://www.unrealengine.com/en-US/download)
- Install [Visual Studio 2022](https://visualstudio.microsoft.com/vs/)
- Install all dependencies mentioned on [official documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/setting-up-visual-studio-development-environment-for-cplusplus-projects-in-unreal-engine?application_version=5.6): .NET desktop development, Desktop development with C++, Universal Windows Platform development, Game Development with C++ (C++ profiling tools, C++ AddressSanitizer, Windows 10 SDK (10.0.18362 or Newer))

Tested on:

- Windows 10 Pro, version 22H2
- Windows 11 Pro, version 24H2
- Windows Server 2025, version 24H2
- Linux/MacOS: work in progress/unstable

## Setup

- To build/compile, run: `.\scripts\build-local.ps1`

- To package, run: `.\scripts\package.ps1` (includes dependency installation)

### Learning Agents Setup

**Quick setup (recommended):** Just run `.\scripts\package.ps1` - it automatically installs all dependencies (TensorBoard, PyTorch, NumPy) and packages the project.

For manual/separate steps:

1. **Install dependencies only** (TensorBoard, PyTorch, NumPy into Unreal Engine's Python):
   ```powershell
   .\scripts\setup.ps1
   ```

2. **Package training build** (Development configuration for headless training):
   ```powershell
   .\scripts\package-training.ps1
   ```

3. **Run training** (single session or batch):
   ```powershell
   .\scripts\run-training-headless.ps1
   # Or for batch training with multiple configurations:
   .\scripts\run-batch-special.ps1
   ```

See [Learning Agents](/LEARNING_AGENTS.md) for detailed documentation.

## Troubleshooting

See [Troubleshooting](/TROUBLESHOOTING.md).