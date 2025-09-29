#!/bin/bash
# Shell script to run TensorBoard using Unreal's pip-installed Python

# Default values
PROJECT_PATH="$(pwd)"
PYTHON_PATH="Intermediate/PipInstall/bin/python"
LOG_DIR="Intermediate/LearningAgents/TensorBoard/runs"
PORT=6006
HOST="0.0.0.0"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --python-path)
            PYTHON_PATH="$2"
            shift 2
            ;;
        --log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --project-path PATH    Path to project directory (default: current directory)"
            echo "  --python-path PATH     Path to Python executable (default: Intermediate/PipInstall/bin/python)"
            echo "  --log-dir DIR          TensorBoard log directory (default: Intermediate/LearningAgents/TensorBoard/runs)"
            echo "  --port PORT            Port for TensorBoard (default: 6006)"
            echo "  --host HOST            Host for TensorBoard (default: 0.0.0.0)"
            echo "  -h, --help             Show this help message"
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
NC='\033[0m' # No Color

# Change to project directory
cd "$PROJECT_PATH" || exit 1

# Check if the Python executable exists
if [ -f "$PYTHON_PATH" ]; then
    echo -e "${GREEN}Found Python executable at: $PYTHON_PATH${NC}"

    # Check if the log directory exists
    if [ -d "$LOG_DIR" ]; then
        echo -e "${GREEN}Found TensorBoard logs at: $LOG_DIR${NC}"

        # Run TensorBoard using the found Python executable
        echo -e "${YELLOW}Starting TensorBoard for FPSGame...${NC}"
        echo -e "${CYAN}TensorBoard will be available at:${NC}"
        echo -e "${CYAN}  - Locally: http://localhost:$PORT${NC}"
        echo -e "${CYAN}  - Network: http://$(hostname -I | awk '{print $1}'):$PORT${NC}"
        echo -e "${YELLOW}Press Ctrl+C to stop TensorBoard${NC}"

        # Check if tensorboard is available
        if "$PYTHON_PATH" -c "import tensorboard" 2>/dev/null; then
            echo -e "${GREEN}TensorBoard is available${NC}"
        else
            echo -e "${YELLOW}TensorBoard not found in Python environment. Installing...${NC}"
            if ! "$PYTHON_PATH" -m pip install tensorboard; then
                echo -e "${RED}Failed to install TensorBoard${NC}"
                exit 1
            fi
        fi

        # Start TensorBoard
        "$PYTHON_PATH" -m tensorboard.main --logdir="$LOG_DIR" --port="$PORT" --host="$HOST"

    else
        echo -e "${RED}TensorBoard log directory not found at: $LOG_DIR${NC}"
        echo -e "${YELLOW}Make sure you have run Learning Agents training to generate logs.${NC}"
        echo -e "${YELLOW}The log directory will be created automatically when training starts.${NC}"
        exit 1
    fi
else
    echo -e "${RED}Python executable not found at: $PYTHON_PATH${NC}"
    echo -e "${YELLOW}Make sure you have the Learning Agents plugin enabled and Python dependencies installed.${NC}"
    echo -e "${YELLOW}You may need to build your project first to generate the Python environment.${NC}"
    echo -e "${YELLOW}Also run install-tensorboard.sh to install TensorBoard.${NC}"
    exit 1
fi

# TensorBoard started successfully
