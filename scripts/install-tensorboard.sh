#!/bin/bash
# Install TensorBoard using Unreal's pip-installed Python
# This script installs TensorBoard in the Python environment that Unreal creates for Learning Agents

# Default values
PROJECT_PATH="$(pwd)"
PYTHON_PATH=""

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
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --project-path PATH    Path to project directory (default: current directory)"
            echo "  --python-path PATH     Path to Python executable (default: auto-detect)"
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

echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}INSTALLING TENSORBOARD FOR LEARNING AGENTS${NC}"
echo -e "${CYAN}======================================${NC}"

# Determine Python path if not provided
if [ -z "$PYTHON_PATH" ]; then
    # Check common locations for Unreal's Python installation
    POSSIBLE_PATHS=(
        "$PROJECT_PATH/Intermediate/PipInstall/bin/python"
        "$PROJECT_PATH/Intermediate/PipInstall/Scripts/python"
        "$PROJECT_PATH/Intermediate/PipInstall/python"
        "$PROJECT_PATH/Intermediate/PipInstall/bin/python3"
        "$PROJECT_PATH/Intermediate/PipInstall/Scripts/python3"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path" ]; then
            PYTHON_PATH="$path"
            break
        fi
    done
fi

# Check if Python executable exists
if [ -z "$PYTHON_PATH" ] || [ ! -f "$PYTHON_PATH" ]; then
    echo -e "${RED}Python executable not found!${NC}"
    echo -e "${YELLOW}Expected locations:${NC}"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo -e "${YELLOW}  - $path${NC}"
    done
    echo -e "\n${YELLOW}Make sure you have:${NC}"
    echo -e "${YELLOW}  1. Learning Agents plugin enabled${NC}"
    echo -e "${YELLOW}  2. Built your project to generate the Python environment${NC}"
    echo -e "${YELLOW}  3. Or specify the Python path with --python-path option${NC}"
    exit 1
fi

echo -e "${GREEN}Found Python executable at: $PYTHON_PATH${NC}"

# Check if pip is available
if ! "$PYTHON_PATH" -m pip --version >/dev/null 2>&1; then
    echo -e "${RED}Pip is not available in this Python environment${NC}"
    echo -e "${YELLOW}This might indicate the Python environment is not properly set up${NC}"
    exit 1
fi

# Install TensorBoard
echo -e "${YELLOW}Installing TensorBoard...${NC}"
if "$PYTHON_PATH" -m pip install tensorboard; then
    echo -e "${GREEN}TensorBoard installed successfully!${NC}"
    
    # Verify installation
    if "$PYTHON_PATH" -c "import tensorboard; print('TensorBoard version:', tensorboard.__version__)" 2>/dev/null; then
        echo -e "${GREEN}TensorBoard verification successful!${NC}"
    else
        echo -e "${YELLOW}Warning: TensorBoard installation verification failed${NC}"
    fi
else
    echo -e "${RED}Failed to install TensorBoard${NC}"
    echo -e "${YELLOW}You may need to check your internet connection or Python environment${NC}"
    exit 1
fi

echo -e "\n${CYAN}======================================${NC}"
echo -e "${GREEN}TENSORBOARD INSTALLATION COMPLETE!${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${WHITE}You can now run TensorBoard with: ./scripts/run-tensorboard.sh${NC}"
