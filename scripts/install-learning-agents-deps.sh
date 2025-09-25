#!/bin/bash
# Install Learning Agents Python Dependencies using UBT PipInstall Mode
# This script uses Unreal Engine's built-in Pip Installer to install dependencies
# exactly like the Editor GUI does automatically
# Usage: ./scripts/install-learning-agents-deps.sh

# Default values
PROJECT_PATH="$(pwd)"
UNREAL_PATH=""
PROJECT_NAME="FPSGame.uproject"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --unreal-path)
            UNREAL_PATH="$2"
            shift 2
            ;;
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --project-path PATH    Path to project directory (default: current directory)"
            echo "  --unreal-path PATH     Path to Unreal Engine installation (default: ~/UE_5.6)"
            echo "  --project-name NAME    Project file name (default: FPSGame.uproject)"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Determine UnrealPath if not provided
if [ -z "$UNREAL_PATH" ]; then
    # Check if UE_5.6 exists in home directory
    if [ -d "$HOME/UE_5.6" ]; then
        UNREAL_PATH="$HOME/UE_5.6"
    else
        # Try common installation paths
        if [ -d "/opt/UnrealEngine/5.6" ]; then
            UNREAL_PATH="/opt/UnrealEngine/5.6"
        elif [ -d "/usr/local/UnrealEngine/5.6" ]; then
            UNREAL_PATH="/usr/local/UnrealEngine/5.6"
        else
            echo "Error: Unreal Engine 5.6 not found in common locations"
            echo "Please specify the path with --unreal-path option"
            echo "Expected locations:"
            echo "  - $HOME/UE_5.6"
            echo "  - /opt/UnrealEngine/5.6"
            echo "  - /usr/local/UnrealEngine/5.6"
            exit 1
        fi
    fi
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}INSTALLING LEARNING AGENTS DEPENDENCIES${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${YELLOW}Unreal Path: $UNREAL_PATH${NC}"
echo -e "${YELLOW}Project Path: $PROJECT_PATH${NC}"
echo -e "${YELLOW}Project Name: $PROJECT_NAME${NC}"

# Paths
RUN_UBT_SCRIPT="$UNREAL_PATH/Engine/Build/BatchFiles/RunUBT.sh"
PROJECT_FILE="$PROJECT_PATH/$PROJECT_NAME"
PIP_INSTALL_PATH="$PROJECT_PATH/Intermediate/PipInstall"

# Check if RunUBT script exists
if [ ! -f "$RUN_UBT_SCRIPT" ]; then
    echo -e "${RED}RunUBT script not found at: $RUN_UBT_SCRIPT${NC}"
    echo -e "${RED}Please check your Unreal Engine installation path${NC}"
    exit 1
fi

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}Project file not found at: $PROJECT_FILE${NC}"
    echo -e "${RED}Please check your project path and name${NC}"
    exit 1
fi

# Check if PipInstall already exists and is not empty
if [ -d "$PIP_INSTALL_PATH" ]; then
    PYTHON_EXE="$PIP_INSTALL_PATH/bin/python"
    if [ -f "$PYTHON_EXE" ]; then
        echo -e "${YELLOW}PipInstall directory already exists with Python executable${NC}"
        echo -e "${YELLOW}Skipping installation...${NC}"
        exit 0
    fi
fi

echo -e "\n${YELLOW}Running UBT PipInstall mode...${NC}"
echo -e "${GRAY}This will install Python dependencies exactly like the Editor GUI does${NC}"

# Run UBT with PipInstall mode
echo -e "${GRAY}Executing: $RUN_UBT_SCRIPT FPSGameEditor Linux Development -Project=\"$PROJECT_FILE\" -Mode=PipInstall${NC}"
"$RUN_UBT_SCRIPT" FPSGameEditor Linux Development -Project="$PROJECT_FILE" -Mode=PipInstall

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PipInstall completed successfully!${NC}"
    
    # Verify installation
    PYTHON_EXE="$PIP_INSTALL_PATH/bin/python"
    if [ -f "$PYTHON_EXE" ]; then
        echo -e "\n${YELLOW}Verifying installation...${NC}"
        "$PYTHON_EXE" -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available())"
        "$PYTHON_EXE" -c "import tensorboard; print('TensorBoard version:', tensorboard.__version__)"
        "$PYTHON_EXE" -c "import numpy; print('NumPy version:', numpy.__version__)"
        echo -e "${GREEN}✓ Core dependencies verified successfully${NC}"
    fi
else
    echo -e "${RED}PipInstall failed${NC}"
    exit 1
fi

echo -e "\n${CYAN}======================================${NC}"
echo -e "${GREEN}INSTALLATION COMPLETED!${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${WHITE}Learning Agents Python dependencies are now available at:${NC}"
echo -e "${GRAY}  $PIP_INSTALL_PATH${NC}"
echo -e "\n${WHITE}Python executable:${NC}"
echo -e "${GRAY}  $PYTHON_EXE${NC}"
echo -e "\n${GREEN}You can now run headless training without opening the Unreal Editor!${NC}"