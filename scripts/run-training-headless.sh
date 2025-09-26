#!/bin/bash
# Headless Training Launcher for FPSGame
# This script launches the packaged game in headless mode for training
# Usage: ./scripts/run-training-headless.sh [--training-build-dir "TrainingBuild"] [--map-name "P_LearningAgentsTrial"] [--log-file "training_log.log"]

# Default values
PROJECT_PATH="$(pwd)"
TRAINING_BUILD_DIR="TrainingBuild"
MAP_NAME="P_LearningAgentsTrial1"  # Default learning map
LOG_FILE="scharacter_training.log"
EXE_NAME="FPSGame"
# Obstacle configuration parameters
USE_OBSTACLES=false
MAX_OBSTACLES=8
MIN_OBSTACLE_SIZE=100.0
MAX_OBSTACLE_SIZE=300.0
OBSTACLE_MODE="Static"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --training-build-dir)
            TRAINING_BUILD_DIR="$2"
            shift 2
            ;;
        --map-name)
            MAP_NAME="$2"
            shift 2
            ;;
        --log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        --exe-name)
            EXE_NAME="$2"
            shift 2
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
            echo "  --training-build-dir DIR    Training build directory (default: TrainingBuild)"
            echo "  --map-name MAP              Map name to load (default: P_LearningAgentsTrial1)"
            echo "  --log-file FILE             Log file name (default: scharacter_training.log)"
            echo "  --exe-name NAME             Executable name (default: FPSGame)"
            echo "  --use-obstacles BOOL        Enable/disable obstacles (default: false)"
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

echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}FPSGAME HEADLESS TRAINING${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${YELLOW}Project Path: $PROJECT_PATH${NC}"
echo -e "${YELLOW}Training Build Dir: $TRAINING_BUILD_DIR${NC}"
echo -e "${YELLOW}Map Name: $MAP_NAME${NC}"
echo -e "${YELLOW}Log File: $LOG_FILE${NC}"
echo -e "${YELLOW}Executable: $EXE_NAME${NC}"

# Find the executable
BUILD_PATH="$PROJECT_PATH/$TRAINING_BUILD_DIR"
EXE_FILES=$(find "$BUILD_PATH" -name "$EXE_NAME" -type f 2>/dev/null)

if [ -z "$EXE_FILES" ]; then
    echo -e "${RED}Executable '$EXE_NAME' not found in build directory: $BUILD_PATH${NC}"
    echo -e "${RED}Please run package-training.sh first to create the training build${NC}"
    exit 1
fi

# Get the first executable found
GAME_EXECUTABLE=$(echo "$EXE_FILES" | head -n1)
EXE_DIRECTORY=$(dirname "$GAME_EXECUTABLE")

echo -e "${GREEN}Found executable: $GAME_EXECUTABLE${NC}"

# Change to executable directory for proper relative path resolution
cd "$EXE_DIRECTORY" || exit 1

echo -e "\n${CYAN}======================================${NC}"
echo -e "${YELLOW}LAUNCHING HEADLESS TRAINING${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${YELLOW}Command Line Arguments:${NC}"
echo -e "${WHITE}  Map: $MAP_NAME${NC}"
echo -e "${WHITE}  Headless Training: Enabled (forces Training mode)${NC}"
echo -e "${WHITE}  Null RHI: Enabled (no rendering)${NC}"
echo -e "${WHITE}  No Sound: Enabled${NC}"
echo -e "${WHITE}  Logging: Enabled to $LOG_FILE${NC}"
echo -e ""
echo -e "${CYAN}Obstacle Configuration:${NC}"
echo -e "${WHITE}  Use Obstacles: $USE_OBSTACLES${NC}"
echo -e "${WHITE}  Max Obstacles: $MAX_OBSTACLES${NC}"
echo -e "${WHITE}  Min Obstacle Size: $MIN_OBSTACLE_SIZE${NC}"
echo -e "${WHITE}  Max Obstacle Size: $MAX_OBSTACLE_SIZE${NC}"
echo -e "${WHITE}  Obstacle Mode: $OBSTACLE_MODE${NC}"

# Build command line arguments for headless training
GAME_ARGS=(
    "$MAP_NAME"                    # Load the training map
    "-headless-training"           # Custom flag to identify headless training mode
    "-nullrhi"                     # Disable rendering for headless mode
    "-nosound"                     # Disable sound
    "-log"                         # Enable logging to console
    "-log=$LOG_FILE"               # Log to specific file
    "-unattended"                  # Run without user interaction
    "-nothreading"                 # Some training setups work better without threading
    "-NoVerifyGC"                  # Skip garbage collection verification for performance
    "-NoLoadStartupPackages"       # Skip loading startup packages for faster boot
    "-FORCELOGFLUSH"               # Force log flushing for real-time monitoring
    "-ini:Engine:[Core.Log]:LogPython=Verbose"  # Enable Python logging for Learning Agents
    "-UseObstacles=$USE_OBSTACLES"  # Enable/disable obstacles
    "-MaxObstacles=$MAX_OBSTACLES"  # Maximum number of obstacles
    "-MinObstacleSize=$MIN_OBSTACLE_SIZE"  # Minimum obstacle size
    "-MaxObstacleSize=$MAX_OBSTACLE_SIZE"  # Maximum obstacle size
    "-ObstacleMode=$OBSTACLE_MODE"  # Obstacle mode (Static/Dynamic)
)

# Debug: Show all game arguments
echo -e "\n${CYAN}Game Arguments:${NC}"
for arg in "${GAME_ARGS[@]}"; do
    echo -e "${WHITE}  $arg${NC}"
done

echo -e "\n${GREEN}Starting headless training...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop training${NC}"
echo -e "${CYAN}Monitor progress in: $LOG_FILE${NC}"
echo -e "${CYAN}TensorBoard logs will be in: Intermediate/LearningAgents/TensorBoard/runs${NC}"

echo -e "\n${GRAY}Executing command:${NC}"
echo -e "${GRAY}$EXE_NAME ${GAME_ARGS[*]}${NC}"

# Function to handle cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Stopping training...${NC}"
    if [ ! -z "$TRAINING_PID" ]; then
        kill "$TRAINING_PID" 2>/dev/null
        wait "$TRAINING_PID" 2>/dev/null
    fi
    echo -e "${CYAN}Training stopped.${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start the training process
echo -e "\n${GREEN}Starting training process...${NC}"
"$GAME_EXECUTABLE" "${GAME_ARGS[@]}" &
TRAINING_PID=$!

echo -e "${GREEN}Training process started with PID: $TRAINING_PID${NC}"
echo -e "${CYAN}You can monitor the log file in another terminal with:${NC}"
echo -e "${WHITE}  tail -f '$LOG_FILE'${NC}"

# Wait for the process to complete
echo -e "\n${YELLOW}Waiting for training to complete...${NC}"
echo -e "${CYAN}Training will run indefinitely (Press Ctrl+C to stop)${NC}"

# Wait for the process to exit
wait "$TRAINING_PID"
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "\n${GREEN}Training completed successfully!${NC}"
elif [ $EXIT_CODE -eq -1 ]; then
    echo -e "\n${YELLOW}Training terminated due to timeout${NC}"
else
    echo -e "\n${YELLOW}Training completed with exit code: $EXIT_CODE${NC}"
fi

echo -e "\n${CYAN}======================================${NC}"
echo -e "${YELLOW}TRAINING SESSION ENDED${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${WHITE}Check the following for results:${NC}"
echo -e "${CYAN}  - Log file: $EXE_DIRECTORY/$LOG_FILE${NC}"
echo -e "${CYAN}  - TensorBoard logs: $PROJECT_PATH/Intermediate/LearningAgents/TensorBoard/runs${NC}"
echo -e "${CYAN}  - Neural network snapshots in project Intermediate directory${NC}"

echo -e "\n${GREEN}To view TensorBoard, run: ./scripts/run-tensorboard.sh${NC}"

# Training session completed

