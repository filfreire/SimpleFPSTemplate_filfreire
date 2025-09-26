#!/bin/bash
# Batch Training Script for FPSGame
# This script runs multiple headless training sessions with different random seeds
# Usage: ./scripts/run-batch-training.sh [--start-seed 1] [--end-seed 30] [--timeout-minutes 60] [--concurrent-runs 1]

# Default values
START_SEED=1
END_SEED=30
TIMEOUT_MINUTES=60
CONCURRENT_RUNS=1
PROJECT_PATH="$(pwd)"
TRAINING_BUILD_DIR="TrainingBuild"
MAP_NAME="P_LearningAgentsTrial1"
EXE_NAME="FPSGame"
RESULTS_DIR="BatchTrainingResults"
CLEANUP_INTERMEDIATE=false
SKIP_EXISTING=true
# Obstacle configuration parameters
USE_OBSTACLES=false
MAX_OBSTACLES=8
MIN_OBSTACLE_SIZE=100.0
MAX_OBSTACLE_SIZE=300.0
OBSTACLE_MODE="Static"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --start-seed)
            START_SEED="$2"
            shift 2
            ;;
        --end-seed)
            END_SEED="$2"
            shift 2
            ;;
        --timeout-minutes)
            TIMEOUT_MINUTES="$2"
            shift 2
            ;;
        --concurrent-runs)
            CONCURRENT_RUNS="$2"
            shift 2
            ;;
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --training-build-dir)
            TRAINING_BUILD_DIR="$2"
            shift 2
            ;;
        --map-name)
            MAP_NAME="$2"
            shift 2
            ;;
        --exe-name)
            EXE_NAME="$2"
            shift 2
            ;;
        --results-dir)
            RESULTS_DIR="$2"
            shift 2
            ;;
        --cleanup-intermediate)
            CLEANUP_INTERMEDIATE=true
            shift
            ;;
        --no-skip-existing)
            SKIP_EXISTING=false
            shift
            ;;
        --use-obstacles)
            USE_OBSTACLES="$2"
            shift 2
            ;;
        --max-obstacles)
            MAX_OBSTACLES="$2"
            shift 2
            ;;
        --min-obstacle-size)
            MIN_OBSTACLE_SIZE="$2"
            shift 2
            ;;
        --max-obstacle-size)
            MAX_OBSTACLE_SIZE="$2"
            shift 2
            ;;
        --obstacle-mode)
            OBSTACLE_MODE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --start-seed SEED           Starting seed number (default: 1)"
            echo "  --end-seed SEED             Ending seed number (default: 30)"
            echo "  --timeout-minutes MINUTES   Timeout per run in minutes (default: 60)"
            echo "  --concurrent-runs RUNS      Number of concurrent runs (default: 1)"
            echo "  --project-path PATH         Project path (default: current directory)"
            echo "  --training-build-dir DIR    Training build directory (default: TrainingBuild)"
            echo "  --map-name MAP              Map name (default: P_LearningAgentsTrial1)"
            echo "  --exe-name NAME             Executable name (default: FPSGame)"
            echo "  --results-dir DIR           Results directory (default: BatchTrainingResults)"
            echo "  --cleanup-intermediate      Clean up intermediate files after each run"
            echo "  --no-skip-existing          Don't skip runs with existing log files"
            echo "  --use-obstacles BOOL        Enable/disable obstacles (default: true)"
            echo "  --max-obstacles NUM         Maximum number of obstacles (default: 8)"
            echo "  --min-obstacle-size SIZE    Minimum obstacle size (default: 100.0)"
            echo "  --max-obstacle-size SIZE    Maximum obstacle size (default: 300.0)"
            echo "  --obstacle-mode MODE         Obstacle mode: Static or Dynamic (default: Static)"
            echo "  -h, --help                  Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

TOTAL_RUNS=$((END_SEED - START_SEED + 1))

echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}FPSGAME BATCH TRAINING${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${YELLOW}Start Seed: $START_SEED${NC}"
echo -e "${YELLOW}End Seed: $END_SEED${NC}"
echo -e "${YELLOW}Total Runs: $TOTAL_RUNS${NC}"
echo -e "${YELLOW}Timeout per run: $TIMEOUT_MINUTES minutes${NC}"
echo -e "${YELLOW}Concurrent runs: $CONCURRENT_RUNS${NC}"
echo -e "${YELLOW}Results directory: $RESULTS_DIR${NC}"
echo -e "${YELLOW}Cleanup intermediate: $CLEANUP_INTERMEDIATE${NC}"
echo -e "${YELLOW}Skip existing: $SKIP_EXISTING${NC}"
echo -e ""
echo -e "${CYAN}Obstacle Configuration:${NC}"
echo -e "${WHITE}  Use Obstacles: $USE_OBSTACLES${NC}"
echo -e "${WHITE}  Max Obstacles: $MAX_OBSTACLES${NC}"
echo -e "${WHITE}  Min Obstacle Size: $MIN_OBSTACLE_SIZE${NC}"
echo -e "${WHITE}  Max Obstacle Size: $MAX_OBSTACLE_SIZE${NC}"
echo -e "${WHITE}  Obstacle Mode: $OBSTACLE_MODE${NC}"

# Create results directory
RESULTS_PATH="$PROJECT_PATH/$RESULTS_DIR"
mkdir -p "$RESULTS_PATH"
echo -e "${GREEN}Created results directory: $RESULTS_PATH${NC}"

# Create subdirectories for organized results
LOGS_DIR="$RESULTS_PATH/Logs"
TENSORBOARD_DIR="$RESULTS_PATH/TensorBoard"
NEURAL_NETWORKS_DIR="$RESULTS_PATH/NeuralNetworks"
SUMMARY_DIR="$RESULTS_PATH/Summary"

mkdir -p "$LOGS_DIR" "$TENSORBOARD_DIR" "$NEURAL_NETWORKS_DIR" "$SUMMARY_DIR"

echo -e "\n${CYAN}Results will be organized in:${NC}"
echo -e "${WHITE}  - Logs: $LOGS_DIR${NC}"
echo -e "${WHITE}  - TensorBoard: $TENSORBOARD_DIR${NC}"
echo -e "${WHITE}  - Neural Networks: $NEURAL_NETWORKS_DIR${NC}"
echo -e "${WHITE}  - Summary: $SUMMARY_DIR${NC}"

# Initialize tracking variables
COMPLETED_RUNS=()
FAILED_RUNS=()
SKIPPED_RUNS=()
START_TIME=$(date)

# Function to run a single training session
run_training_session() {
    local seed=$1
    local session_id=$2
    
    local log_file="training_seed_${seed}.log"
    local log_path="$LOGS_DIR/$log_file"
    
    # Check if we should skip this run
    if [ "$SKIP_EXISTING" = true ] && [ -f "$log_path" ]; then
        echo -e "${YELLOW}Skipping seed $seed - log file already exists${NC}"
        return 2  # SKIPPED
    fi
    
    echo -e "\n${GREEN}Starting training session $session_id (Seed: $seed)...${NC}"
    echo -e "${CYAN}Log file: $log_file${NC}"
    
    # Run the training session
    if timeout "${TIMEOUT_MINUTES}m" "$PROJECT_PATH/scripts/run-training-headless.sh" \
        --log-file "$log_file" \
        --training-build-dir "$TRAINING_BUILD_DIR" \
        --map-name "$MAP_NAME" \
        --exe-name "$EXE_NAME" \
        --use-obstacles "$USE_OBSTACLES" \
        --max-obstacles "$MAX_OBSTACLES" \
        --min-obstacle-size "$MIN_OBSTACLE_SIZE" \
        --max-obstacle-size "$MAX_OBSTACLE_SIZE" \
        --obstacle-mode "$OBSTACLE_MODE"; then
        echo -e "${GREEN}Training session $session_id completed successfully!${NC}"
        return 0  # SUCCESS
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo -e "${YELLOW}Training session $session_id timed out after $TIMEOUT_MINUTES minutes${NC}"
            return 1  # TIMEOUT
        else
            echo -e "${YELLOW}Training session $session_id completed with exit code: $exit_code${NC}"
            return 1  # FAILED
        fi
    fi
}

# Function to copy results after training
copy_training_results() {
    local seed=$1
    local status=$2
    
    if [ "$status" = "SUCCESS" ] || [ "$status" = "TIMEOUT" ]; then
        # Copy log file
        local source_log="$PROJECT_PATH/$TRAINING_BUILD_DIR/Linux/$EXE_NAME/Saved/Logs/training_seed_${seed}.log"
        local dest_log="$LOGS_DIR/training_seed_${seed}.log"
        
        echo -e "${CYAN}Attempting to copy log file for seed $seed...${NC}"
        echo -e "${GRAY}Source: $source_log${NC}"
        echo -e "${GRAY}Destination: $dest_log${NC}"
        
        if [ -f "$source_log" ]; then
            cp "$source_log" "$dest_log"
            echo -e "${GREEN}Copied log file: $source_log -> $dest_log${NC}"
        else
            echo -e "${YELLOW}Log file not found: $source_log${NC}"
            # Check if the directory exists
            local log_dir=$(dirname "$source_log")
            if [ -d "$log_dir" ]; then
                echo -e "${YELLOW}Log directory exists: $log_dir${NC}"
                local available_logs=$(ls "$log_dir"/*.log 2>/dev/null | wc -l)
                if [ "$available_logs" -gt 0 ]; then
                    echo -e "${YELLOW}Available log files:${NC}"
                    ls "$log_dir"/*.log 2>/dev/null | while read -r log_file; do
                        echo -e "${GRAY}  - $(basename "$log_file")${NC}"
                    done
                else
                    echo -e "${YELLOW}No .log files found in directory${NC}"
                fi
            else
                echo -e "${RED}Log directory does not exist: $log_dir${NC}"
            fi
        fi
        
        # Copy TensorBoard runs
        local tensorboard_source="$PROJECT_PATH/Intermediate/LearningAgents/TensorBoard/runs"
        if [ -d "$tensorboard_source" ]; then
            local latest_run=$(ls -t "$tensorboard_source" | head -n1)
            if [ -n "$latest_run" ]; then
                local tensorboard_dest="$TENSORBOARD_DIR/seed_${seed}"
                cp -r "$tensorboard_source/$latest_run" "$tensorboard_dest"
            fi
        fi
        
        # Copy neural network files
        local neural_net_source="$PROJECT_PATH/Intermediate/LearningAgents/Training0"
        if [ -d "$neural_net_source" ]; then
            local neural_net_dest="$NEURAL_NETWORKS_DIR/seed_${seed}"
            cp -r "$neural_net_source" "$neural_net_dest"
        fi
        
        # Cleanup intermediate files if requested
        if [ "$CLEANUP_INTERMEDIATE" = true ]; then
            rm -rf "$tensorboard_source" 2>/dev/null
            rm -rf "$neural_net_source" 2>/dev/null
        fi
    fi
}

# Main training loop
echo -e "\n${CYAN}======================================${NC}"
echo -e "${YELLOW}STARTING BATCH TRAINING${NC}"
echo -e "${CYAN}======================================${NC}"

current_run=1

for ((seed=START_SEED; seed<=END_SEED; seed++)); do
    session_id="Run $current_run/$TOTAL_RUNS"
    echo -e "\n${CYAN}[$session_id] Processing seed $seed...${NC}"
    
    run_training_session "$seed" "$session_id"
    status=$?
    
    # Track results
    case $status in
        0) COMPLETED_RUNS+=($seed) ;;  # SUCCESS
        1) COMPLETED_RUNS+=($seed) ;;  # TIMEOUT - now treated as successful
        2) SKIPPED_RUNS+=($seed) ;;   # SKIPPED
        3) FAILED_RUNS+=($seed) ;;    # FAILED
    esac
    
    # Copy results
    case $status in
        0) copy_training_results "$seed" "SUCCESS" ;;
        1) copy_training_results "$seed" "TIMEOUT" ;;
        2) copy_training_results "$seed" "SKIPPED" ;;
        3) copy_training_results "$seed" "FAILED" ;;
    esac
    
    ((current_run++))
    
    # Add delay between runs to avoid resource conflicts
    if [ $current_run -le $TOTAL_RUNS ]; then
        echo -e "${GRAY}Waiting 30 seconds before next run...${NC}"
        sleep 30
    fi
done

# Generate summary report
END_TIME=$(date)
TOTAL_DURATION=$(($(date -d "$END_TIME" +%s) - $(date -d "$START_TIME" +%s)))
DURATION_FORMATTED=$(printf '%02d:%02d:%02d' $((TOTAL_DURATION/3600)) $((TOTAL_DURATION%3600/60)) $((TOTAL_DURATION%60)))

SUMMARY_REPORT="FPSGAME BATCH TRAINING SUMMARY REPORT
=====================================
Start Time: $START_TIME
End Time: $END_TIME
Total Duration: $DURATION_FORMATTED

CONFIGURATION:
- Seed Range: $START_SEED to $END_SEED
- Total Runs: $TOTAL_RUNS
- Timeout per run: $TIMEOUT_MINUTES minutes
- Concurrent runs: $CONCURRENT_RUNS

RESULTS:
- Successful runs: ${#COMPLETED_RUNS[@]} - Seeds: ${COMPLETED_RUNS[*]}
- Failed runs: ${#FAILED_RUNS[@]} - Seeds: ${FAILED_RUNS[*]}
- Skipped runs: ${#SKIPPED_RUNS[@]} - Seeds: ${SKIPPED_RUNS[*]}

FILES GENERATED:
- Log files: $LOGS_DIR
- TensorBoard runs: $TENSORBOARD_DIR
- Neural network files: $NEURAL_NETWORKS_DIR
- This summary: $SUMMARY_DIR

NEXT STEPS:
1. Review individual log files for detailed training progress
2. Use TensorBoard to visualize training metrics: ./scripts/run-tensorboard.sh --log-dir \"$TENSORBOARD_DIR\"
3. Compare neural network performance across different seeds
4. Analyze results to determine optimal hyperparameters"

SUMMARY_FILE="$SUMMARY_DIR/batch_training_summary_$(date +%Y-%m-%d_%H-%M-%S).txt"
echo "$SUMMARY_REPORT" > "$SUMMARY_FILE"

echo -e "\n${CYAN}======================================${NC}"
echo -e "${GREEN}BATCH TRAINING COMPLETED${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${YELLOW}Total Duration: $DURATION_FORMATTED${NC}"
echo -e "${GREEN}Successful runs: ${#COMPLETED_RUNS[@]}/$TOTAL_RUNS${NC}"
echo -e "${RED}Failed runs: ${#FAILED_RUNS[@]}/$TOTAL_RUNS${NC}"
echo -e "${YELLOW}Skipped runs: ${#SKIPPED_RUNS[@]}/$TOTAL_RUNS${NC}"

echo -e "\n${CYAN}Results saved to: $RESULTS_PATH${NC}"
echo -e "${CYAN}Summary report: $SUMMARY_FILE${NC}"

echo -e "\n${GREEN}To view TensorBoard for all runs:${NC}"
echo -e "${WHITE}./scripts/run-tensorboard.sh --log-dir \"$TENSORBOARD_DIR\"${NC}"

# Batch training completed
