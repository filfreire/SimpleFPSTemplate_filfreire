# Batch Training Scripts for FPSGame

This directory contains scripts for running multiple headless training sessions with different random seeds.

## Scripts

### `run-batch-training.ps1` (Windows PowerShell)
### `run-batch-training.sh` (Linux/macOS Bash)

## Usage

### Basic Usage (30 runs with seeds 1-30, 60 minutes each)
```powershell
# Windows
.\scripts\run-batch-training.ps1

# Linux/macOS
./scripts/run-batch-training.sh
```

### Custom Configuration
```powershell
# Windows - Custom seed range and timeout
.\scripts\run-batch-training.ps1 -StartSeed 1 -EndSeed 10 -TimeoutMinutes 30

# Linux/macOS - Custom seed range and timeout
./scripts/run-batch-training.sh --start-seed 1 --end-seed 10 --timeout-minutes 30
```

### Advanced Options
```powershell
# Windows - Full customization
.\scripts\run-batch-training.ps1 `
    -StartSeed 1 `
    -EndSeed 50 `
    -TimeoutMinutes 120 `
    -ResultsDir "MyTrainingResults" `
    -CleanupIntermediate `
    -SkipExisting:$false `
    -UseObstacles:$false `
    -MaxObstacles 12 `
    -ObstacleMode "Dynamic"

# Linux/macOS - Full customization
./scripts/run-batch-training.sh \
    --start-seed 1 \
    --end-seed 50 \
    --timeout-minutes 120 \
    --results-dir "MyTrainingResults" \
    --cleanup-intermediate \
    --no-skip-existing
```

## Parameters

| Parameter | Windows | Linux/macOS | Default | Description |
|-----------|---------|-------------|---------|-------------|
| Start Seed | `-StartSeed` | `--start-seed` | 1 | Starting random seed number |
| End Seed | `-EndSeed` | `--end-seed` | 30 | Ending random seed number |
| Timeout | `-TimeoutMinutes` | `--timeout-minutes` | 60 | Timeout per run in minutes |
| Concurrent Runs | `-ConcurrentRuns` | `--concurrent-runs` | 1 | Number of concurrent runs |
| Results Directory | `-ResultsDir` | `--results-dir` | BatchTrainingResults | Directory to store results |
| Cleanup Intermediate | `-CleanupIntermediate` | `--cleanup-intermediate` | false | Clean up intermediate files after each run |
| Skip Existing | `-SkipExisting` | `--no-skip-existing` | true | Skip runs with existing log files |
| Use Obstacles | `-UseObstacles` | `--use-obstacles` | false | Enable/disable obstacles in training |
| Max Obstacles | `-MaxObstacles` | `--max-obstacles` | 8 | Maximum number of obstacles |
| Min Obstacle Size | `-MinObstacleSize` | `--min-obstacle-size` | 100.0 | Minimum obstacle size |
| Max Obstacle Size | `-MaxObstacleSize` | `--max-obstacle-size` | 300.0 | Maximum obstacle size |
| Obstacle Mode | `-ObstacleMode` | `--obstacle-mode` | "Static" | Obstacle mode: "Static" or "Dynamic" |

## Output Structure

The script creates a organized directory structure:

```
BatchTrainingResults/
├── Logs/                          # Individual training log files
│   ├── training_seed_1.log
│   ├── training_seed_2.log
│   └── ...
├── TensorBoard/                   # TensorBoard run data
│   ├── seed_1/
│   ├── seed_2/
│   └── ...
├── NeuralNetworks/                # Neural network snapshots
│   ├── seed_1/
│   │   ├── Snapshots/
│   │   │   ├── policy_0.bin
│   │   │   ├── critic_0.bin
│   │   │   ├── encoder_0.bin
│   │   │   └── decoder_0.bin
│   │   └── Configs/
│   ├── seed_2/
│   └── ...
└── Summary/                       # Summary reports
    └── batch_training_summary_YYYY-MM-DD_HH-mm-ss.txt
```

## Conflict Resolution

The script automatically handles potential conflicts:

### ✅ Log Files
- **No conflicts**: Each run uses a unique log file name (`training_seed_X.log`)
- **Location**: Copied to organized `Logs/` directory

### ✅ TensorBoard Runs
- **Solution**: Each run's TensorBoard data is copied to a unique directory (`seed_X/`)
- **Location**: Organized in `TensorBoard/` directory

### ✅ Neural Network Files
- **Solution**: Each run's neural network snapshots are copied to a unique directory (`seed_X/`)
- **Location**: Organized in `NeuralNetworks/` directory

## Monitoring Progress

### Real-time Monitoring
```powershell
# Windows - Monitor logs
Get-Content -Path "BatchTrainingResults\Logs\training_seed_1.log" -Wait

# Linux/macOS - Monitor logs
tail -f BatchTrainingResults/Logs/training_seed_1.log
```

### TensorBoard Visualization
```powershell
# Windows - View all runs
.\scripts\run-tensorboard.ps1 --log-dir "BatchTrainingResults\TensorBoard"

# Linux/macOS - View all runs
./scripts/run-tensorboard.sh --log-dir "BatchTrainingResults/TensorBoard"
```

## Obstacle Configuration Examples

### Training WITHOUT Obstacles (Default)
```powershell
# Windows - Default settings (obstacles disabled)
.\scripts\run-batch-training.ps1 -StartSeed 1 -EndSeed 6 -TimeoutMinutes 5

# Linux/macOS - Default settings (obstacles disabled)
./scripts/run-batch-training.sh --start-seed 1 --end-seed 6 --timeout-minutes 5
```

### Training WITH Obstacles
```powershell
# Windows - Enable obstacles
.\scripts\run-batch-training.ps1 -StartSeed 1 -EndSeed 6 -TimeoutMinutes 5 -UseObstacles:$true

# Linux/macOS - Enable obstacles
./scripts/run-batch-training.sh --start-seed 1 --end-seed 6 --timeout-minutes 5 --use-obstacles true
```

### Custom Obstacle Configuration
```powershell
# Windows - Custom obstacles
.\scripts\run-batch-training.ps1 -StartSeed 1 -EndSeed 6 -TimeoutMinutes 5 -MaxObstacles 12 -ObstacleMode "Dynamic"

# Linux/macOS - Custom obstacles
./scripts/run-batch-training.sh --start-seed 1 --end-seed 6 --timeout-minutes 5 --max-obstacles 12 --obstacle-mode "Dynamic"
```

## Example Workflow

1. **Start batch training**:
   ```bash
   ./scripts/run-batch-training.sh --start-seed 1 --end-seed 30 --timeout-minutes 60
   ```

2. **Monitor progress** (in another terminal):
   ```bash
   tail -f BatchTrainingResults/Logs/training_seed_1.log
   ```

3. **View TensorBoard** (in another terminal):
   ```bash
   ./scripts/run-tensorboard.sh --log-dir "BatchTrainingResults/TensorBoard"
   ```

4. **Review results**:
   - Check `BatchTrainingResults/Summary/` for overall statistics
   - Compare individual log files in `BatchTrainingResults/Logs/`
   - Analyze neural network performance across different seeds

## Prerequisites

- Training build must exist (`TrainingBuild/` directory)
- Learning Agents plugin must be configured
- FPSCharacterManager must be properly set up in Unreal Editor

## Troubleshooting

### Common Issues

1. **Training build not found**:
   ```bash
   ./scripts/package-training.sh
   ```

2. **Permission denied** (Linux/macOS):
   ```bash
   chmod +x scripts/run-batch-training.sh
   ```

3. **Out of disk space**:
   - Use `--cleanup-intermediate` to clean up intermediate files
   - Monitor disk usage during long training sessions

4. **Memory issues**:
   - Reduce `--concurrent-runs` to 1
   - Reduce `--timeout-minutes` for shorter runs

## Performance Tips

- **Sequential runs**: Use `--concurrent-runs 1` for stability
- **Resource management**: Use `--cleanup-intermediate` to save disk space
- **Resume capability**: Use `--skip-existing` to resume interrupted batches
- **Monitoring**: Run TensorBoard in a separate terminal for real-time visualization
