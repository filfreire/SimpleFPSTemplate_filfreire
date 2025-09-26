# Obstacle System Usage Guide

This document explains how to use the obstacle system in the SimpleFPSTemplate project for both static and dynamic obstacle modes.

## Overview

The obstacle system consists of two main components:
- `AFPSObstacleActor`: Individual obstacle actors that provide collision detection
- `UFPSObstacleManager`: Manages obstacle placement and behavior in static/dynamic modes

## Static Mode

In static mode, obstacles are placed once at the beginning of training and remain in the same positions throughout all training iterations.

### Setup for Static Mode

1. In your training environment Blueprint:
   - Set `bUseObstacles` to `true`
   - Set `MaxObstacles` to desired number (default: 8)
   - Set `MinObstacleSize` and `MaxObstacleSize` for obstacle dimensions
   - The obstacle manager will automatically initialize obstacles on first reset

2. Obstacles will be randomly placed within the environment bounds, avoiding agent and target spawn locations.

## Dynamic Mode

In dynamic mode, obstacles are regenerated (deleted and recreated) at the start of each training iteration, providing varied environments.

### Setup for Dynamic Mode

1. In your training environment Blueprint:
   - Set `bUseObstacles` to `true`
   - Set `MaxObstacles` to desired number
   - Set obstacle size parameters
   - Call `SetObstacleMode(Dynamic)` on the obstacle manager

2. Obstacles will be regenerated automatically during each episode reset.

## Configuration Parameters

### Training Environment Settings

- `bUseObstacles`: Enable/disable obstacle system
- `MaxObstacles`: Maximum number of obstacles to spawn
- `MinObstacleSize`: Minimum obstacle size (width/depth)
- `MaxObstacleSize`: Maximum obstacle size (width/depth)

### Obstacle Manager Settings

- `ObstacleMode`: Static or Dynamic mode
- `EnvironmentCenter`: Center point for obstacle placement
- `EnvironmentBounds`: Bounds for obstacle placement
- `MinDistanceFromAgents`: Minimum distance from agent spawn points
- `MinDistanceFromTarget`: Minimum distance from target spawn points

## Blueprint Usage

### Creating Obstacles Manually

```cpp
// In Blueprint or C++
UFPSObstacleManager* ObstacleManager = NewObject<UFPSObstacleManager>(this);
ObstacleManager->EnvironmentCenter = FVector(0, 0, 0);
ObstacleManager->EnvironmentBounds = FVector(2000, 2000, 0);
ObstacleManager->MaxObstacles = 10;
ObstacleManager->SetObstacleMode(EObstacleMode::Static);
ObstacleManager->InitializeObstacles();
```

### Checking for Obstacle Collisions

```cpp
// Check if a location is blocked by obstacles
bool bIsBlocked = ObstacleManager->IsLocationBlocked(Location, AgentRadius);
```

### Switching Modes During Runtime

```cpp
// Switch to dynamic mode
ObstacleManager->SetObstacleMode(EObstacleMode::Dynamic);

// Regenerate obstacles manually
ObstacleManager->RegenerateObstacles();
```

## Reward System Integration

The training environment automatically applies collision penalties:
- **Obstacle Collision Penalty**: -10.0 reward points when agent collides with obstacles
- **Collision Detection**: Uses agent radius (50 units) for collision detection

## Performance Considerations

- Static mode: Better performance, consistent environment
- Dynamic mode: More varied training, slightly higher CPU usage during resets
- Obstacle count: Balance between challenge and performance (recommended: 5-15 obstacles)

## Troubleshooting

### Common Issues

1. **Obstacles not appearing**: Check that `bUseObstacles` is enabled and obstacle manager is initialized
2. **Agents spawning inside obstacles**: Increase `MinDistanceFromAgents` or reduce obstacle density
3. **Performance issues**: Reduce `MaxObstacles` or use static mode

### Debug Logging

Enable verbose logging to see obstacle generation and collision detection:
```
LogTemp: VeryVerbose
```

## Command-Line Configuration

The obstacle system can be configured via command-line parameters when running headless training:

### PowerShell Script Usage

```powershell
# Static obstacles (default)
.\scripts\run-training-headless.ps1 -UseObstacles $true -MaxObstacles 8 -MinObstacleSize 100 -MaxObstacleSize 300 -ObstacleMode "Static"

# Dynamic obstacles (regenerated each episode)
.\scripts\run-training-headless.ps1 -UseObstacles $true -MaxObstacles 12 -MinObstacleSize 50 -MaxObstacleSize 400 -ObstacleMode "Dynamic"

# No obstacles (for baseline comparison)
.\scripts\run-training-headless.ps1 -UseObstacles $false

# Many small obstacles
.\scripts\run-training-headless.ps1 -UseObstacles $true -MaxObstacles 20 -MinObstacleSize 50 -MaxObstacleSize 150 -ObstacleMode "Static"
```

### Command-Line Parameters

- `-UseObstacles`: Enable/disable obstacles (true/false)
- `-MaxObstacles`: Maximum number of obstacles to spawn (integer)
- `-MinObstacleSize`: Minimum obstacle size (float)
- `-MaxObstacleSize`: Maximum obstacle size (float)
- `-ObstacleMode`: Obstacle behavior mode ("Static" or "Dynamic")

### Example Scripts

Run the example script to see different obstacle configurations:
```powershell
.\scripts\run-training-with-obstacles.ps1
```

## Example Blueprint Setup

1. Open your training environment Blueprint
2. In the Details panel, find the "Obstacles" category
3. Enable `bUseObstacles`
4. Set desired obstacle parameters
5. The system will automatically handle obstacle management during training

**Note**: Command-line parameters override Blueprint settings when running headless training.

