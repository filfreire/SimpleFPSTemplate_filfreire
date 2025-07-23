# Spectator Camera System

This document explains how to use the newly implemented spectator camera system that allows you to observe all FPS characters during gameplay without affecting their cameras.

## Overview

The spectator camera system provides:
- A free-flying camera for observing gameplay
- Seamless switching between FPS character control and spectator mode
- Independent camera controls that don't interfere with character input
- Smooth camera transitions

## How to Use

### Quick Start
1. Start playing your FPS game normally
2. Press **F** to toggle into spectator mode
3. Use **WASD** to move the camera around
4. Use **Q/E** to move up/down
5. Use **Mouse** to look around
6. Press **F** again to return to your character

### Controls in Spectator Mode
- **W/S**: Move forward/backward
- **A/D**: Move left/right  
- **Q/E**: Move up/down
- **Mouse**: Look around
- **F**: Return to character control

## Technical Details

### Components
- **AFPSSpectatorCamera**: The actor that provides the spectator camera functionality
- **AFPSPlayerController**: Modified to handle spectator mode switching and input routing

### Key Features
- **Non-Intrusive**: FPS characters continue functioning normally when you spectate
- **Smooth Transitions**: Camera blends smoothly between character and spectator views
- **Input Isolation**: Spectator input doesn't affect character movement
- **Persistent Camera**: Spectator camera maintains its position when you switch back to character

### Configuration
You can adjust spectator camera settings in the editor:
- **Movement Speed**: How fast the camera moves
- **Look Sensitivity**: Mouse sensitivity for camera rotation

## Setup for New Levels

The spectator system is automatically set up when you use the FPSPlayerController. No additional setup is required for new levels.

## Troubleshooting

### Camera not working
- Ensure your GameMode uses the modified FPSPlayerController
- Check that the F key binding is configured correctly in Input settings

### Input conflicts
- The system automatically handles input routing based on spectator state
- Regular character input is disabled while spectating

### Performance
- The spectator camera is lightweight and shouldn't impact game performance
- Only one spectator camera is created per player controller 