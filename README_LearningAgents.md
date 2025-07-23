# FPS Learning Agents Implementation

This document explains how to use the UE5.6 Learning Agents system implemented for FPSCharacter to train agents to reach target actors.

## Overview

The learning agents system consists of several key components:

1. **FPSTargetActor** - The target that agents need to reach
2. **FPSCharacterInteractor** - Handles observations and actions for the agents
3. **FPSCharacterTrainingEnvironment** - Manages rewards and episode completion
4. **FPSCharacterManagerComponent** - Component-based manager
5. **FPSCharacterManager** - Main actor that orchestrates the learning system

## Learning Goal

The agents are trained to:
- Navigate towards a target actor placed in the scene
- Get rewarded based on how close they are to the target
- Get additional rewards for facing the target
- Complete episodes when they reach the target or exceed time limits

## Setup Instructions

### 1. Prepare Your Level

1. Open your FPS level in the Unreal Editor
2. Place one or more **FPSCharacter** actors in the level (not just as the player pawn)
3. Place an **FPSTargetActor** in the level
4. Place an **FPSCharacterManager** actor in the level

### 2. Configure the FPSCharacterManager

In the **FPSCharacterManager** actor properties:

#### Manager Settings
- **Run Mode**: Choose between Training, Inference, or ReInitialize
- **Random Seed**: Set a random seed for reproducible results

#### Environment
- **Target Actor**: Assign the FPSTargetActor you placed in the level

#### Neural Networks
You need to create and assign four neural network assets:
- **Encoder Neural Network**
- **Policy Neural Network** 
- **Decoder Neural Network**
- **Critic Neural Network**

To create these:
1. Right-click in Content Browser → Learning Agents → Neural Network
2. Create 4 neural network assets with appropriate names
3. Assign them to the FPSCharacterManager

#### Learning Settings
Configure the training parameters:
- **Policy Settings**: Neural network configuration for the policy
- **Critic Settings**: Neural network configuration for the critic
- **Training Settings**: PPO training hyperparameters
- **Training Game Settings**: Episode and timing settings

### 3. Configure the Target Actor

In the **FPSTargetActor** properties:
- **Reach Distance**: How close agents need to get to complete the task (default: 150 units)

### 4. Configure Training Environment

The training environment can be configured through the FPSCharacterManager:

#### Reward Settings
- **Reach Target Reward**: Reward given when agent reaches target (default: 100.0)
- **Distance Reward Scale**: Continuous reward based on distance to target (default: 0.1)
- **Movement Towards Target Reward**: Reward for moving closer to target (default: 0.5)
- **Facing Target Reward**: Reward for looking at the target (default: 0.2)
- **Time Step Penalty**: Small penalty per step to encourage efficiency (default: -0.01)
- **Max Episode Length**: Maximum steps before episode ends (default: 1000)

#### Environment Settings
- **Reset Center**: Center point for resetting agents and targets
- **Reset Bounds**: How far from center agents/targets can spawn
- **Min Distance Between Character And Target**: Minimum spawn distance between agent and target

## Observations

The agents observe:
- Character location (3D position)
- Character velocity (3D velocity)
- Character forward direction (3D unit vector)
- Target location (3D position)
- Direction to target (3D unit vector)
- Distance to target (scalar)
- Facing alignment (-1 to 1, where 1 means perfectly aligned with target)

## Actions

The agents can perform:
- **Move Forward/Backward** (-1 to 1)
- **Move Left/Right** (-1 to 1)
- **Turn** (yaw rotation, -1 to 1)
- **Look Up/Down** (pitch rotation, -1 to 1)

## Training Process

1. **Start Training**: Set Run Mode to "Training" and play the level
2. **Monitor Progress**: Check the Output Log for training information
3. **Episode Reset**: Agents and targets are randomly repositioned when episodes end
4. **Reward Feedback**: Agents receive rewards based on their performance

## Inference

Once trained:
1. Set Run Mode to "Inference" 
2. The trained agents will use their learned policy to navigate to targets
3. No training updates occur during inference

## Troubleshooting

### No Agents Found
If you see "No FPSCharacter agents found!":
- Ensure you have FPSCharacter actors (or Blueprints derived from FPSCharacter) placed in the level
- Don't rely only on the PlayerPawn - you need actual actor instances

### Neural Network Warnings
If you see neural network warnings:
- Create and assign all four required neural network assets
- Make sure they're properly configured in the FPSCharacterManager

### Target Actor Issues
If agents aren't responding to the target:
- Verify the Target Actor is assigned in the FPSCharacterManager
- Check that the FPSTargetActor is placed in the level and visible

## File Structure

```
Source/FPSGame/Learning/
├── FPSTargetActor.h/.cpp           # Target actor that agents try to reach
├── FPSCharacterInteractor.h/.cpp   # Handles observations and actions
├── FPSCharacterTrainingEnvironment.h/.cpp  # Manages rewards and episodes
├── FPSCharacterManagerComponent.h/.cpp     # Component-based manager
└── FPSCharacterManager.h/.cpp      # Main learning system orchestrator
```

## Next Steps

- Experiment with different reward values to achieve desired behaviors
- Adjust neural network architectures for better performance
- Create multiple target configurations for varied training scenarios
- Implement additional observations (health, inventory, etc.) if needed
- Add more complex action spaces (jumping, shooting, etc.) for advanced behaviors 