# Learning agents

## Useful docs and repositories:

- <https://dev.epicgames.com/community/learning/courses/GAR/unreal-engine-learning-agents-5-5/bZnJ/unreal-engine-learning-agents-5-5>
- <https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/LearningAgents>
- <https://github.com/Olliebrown/LearningAgentsDriveCPP/tree/5.6.0>
- <https://github.com/XanderBert/Unreal-Engine-Learning-Agents-Learning-Environment>
- <https://antho6222.github.io/project9.html>


## Random seed and timeout example

```powershell
.\scripts\run-training-headless.ps1 -RandomSeed 42 -LearningRatePolicy 0.0005 -EpsilonClip 0.1
```

## Headless Training Examples

The project includes a comprehensive headless training system with configurable hyperparameters, timeouts, and obstacle systems. Here are practical examples:

- Run training for 30 minutes with custom hyperparameters:

```powershell
.\scripts\run-training-headless.ps1 -TimeoutMinutes 30 -RandomSeed 1234 -LearningRatePolicy 0.0003 -LearningRateCritic 0.001 -EpsilonClip 0.2
```

- Example with different PPO settings and batch sizes:

```powershell
.\scripts\run-training-headless.ps1 -TimeoutMinutes 60 -RandomSeed 5678 -LearningRatePolicy 0.0001 -LearningRateCritic 0.0005 -EpsilonClip 0.15 -PolicyBatchSize 2048 -CriticBatchSize 8192 -IterationsPerGather 64 -DiscountFactor 0.995 -GaeLambda 0.9 -ActionEntropyWeight 0.01
```

- Examples with different obstacle modes:

```powershell
# Static obstacles - same positions throughout training
.\scripts\run-training-headless.ps1 -TimeoutMinutes 45 -UseObstacles $true -MaxObstacles 10 -MinObstacleSize 30 -MaxObstacleSize 80 -ObstacleMode "Static" -LearningRatePolicy 0.0002

# Dynamic obstacles - regenerated each episode
.\scripts\run-training-headless.ps1 -TimeoutMinutes 45 -UseObstacles $true -MaxObstacles 15 -MinObstacleSize 20 -MaxObstacleSize 100 -ObstacleMode "Dynamic" -LearningRatePolicy 0.0002

# No obstacles - baseline comparison
.\scripts\run-training-headless.ps1 -TimeoutMinutes 45 -UseObstacles $false -LearningRatePolicy 0.0002
```

## Parameters

**Obstacle parameters:**
- `-UseObstacles $true`: Enable obstacle system
- `-MaxObstacles 10`: Number of obstacles to spawn
- `-MinObstacleSize 30`: Minimum obstacle size
- `-MaxObstacleSize 80`: Maximum obstacle size
- `-ObstacleMode "Static"`: Obstacles stay in same positions
- `-ObstacleMode "Dynamic"`: Obstacles regenerate each episode

**Training Control parameters:**
- `-TimeoutMinutes`: Training duration (0 = run indefinitely)
- `-RandomSeed`: Random seed for reproducibility
- `-MapName`: Training map to use

**PPO Hyperparameters:**
- `-LearningRatePolicy`: Policy network learning rate (default: 0.0001)
- `-LearningRateCritic`: Critic network learning rate (default: 0.001)
- `-EpsilonClip`: PPO clipping parameter (default: 0.2)
- `-PolicyBatchSize`: Policy batch size (default: 1024)
- `-CriticBatchSize`: Critic batch size (default: 4096)
- `-IterationsPerGather`: Training iterations per gather (default: 32)
- `-NumberOfIterations`: Total training iterations (default: 1000000)
- `-DiscountFactor`: Reward discount factor (default: 0.99)
- `-GaeLambda`: GAE lambda parameter (default: 0.95)
- `-ActionEntropyWeight`: Action entropy weight (default: 0.0)

**Obstacle Configuration parameters:**
- `-UseObstacles`: Enable/disable obstacles (true/false)
- `-MaxObstacles`: Maximum obstacles to spawn (default: 8)
- `-MinObstacleSize`: Minimum obstacle size (default: 100.0)
- `-MaxObstacleSize`: Maximum obstacle size (default: 300.0)
- `-ObstacleMode`: Obstacle behavior ("Static" or "Dynamic")

## Monitoring Training

Monitor training progress in real-time:

```powershell
# View training logs
Get-Content -Path "fpscharacter_training.log" -Wait

# View TensorBoard (in another terminal)
.\scripts\run-tensorboard.ps1
```

## Runing Batches

Example with Deactivated Obstacles (No Obstacles):

```powershell
.\scripts\run-batch-training.ps1 -StartSeed 1 -EndSeed 5 -TimeoutMinutes 10 -UseObstacles $false -ResultsDir "results_NoObstacles_5Seeds_10min"
```

Example with Active Dynamic obstacles:

```powershell
.\scripts\run-batch-training.ps1 -StartSeed 1 -EndSeed 5 -TimeoutMinutes 10 -UseObstacles $true -ObstacleMode "Dynamic" -ResultsDir "results_DynamicObstacles_5Seeds_10min"
```

Example for running Batches on Linux:

```bash
## **3. Active Dynamic Obstacles**
./scripts/run-batch-training.sh --start-seed 1 --end-seed 5 --timeout-minutes 10 --use-obstacles true --obstacle-mode "Dynamic" --results-dir "BatchTrainingResults_DynamicObstacles_5Seeds_10min"
```
