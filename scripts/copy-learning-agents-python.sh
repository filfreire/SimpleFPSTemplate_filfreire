#!/bin/bash
# Copy LearningAgents Python Content to Training Build
# This script copies the LearningAgents Python content from the Engine to the packaged build
# so that headless training can find the required Python files

# Default values
PROJECT_PATH="$(pwd)"
TRAINING_BUILD_DIR="TrainingBuild"
UNREAL_PATH=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --training-build-dir)
            TRAINING_BUILD_DIR="$2"
            shift 2
            ;;
        --unreal-path)
            UNREAL_PATH="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --project-path PATH        Path to project directory (default: current directory)"
            echo "  --training-build-dir DIR   Training build directory name (default: TrainingBuild)"
            echo "  --unreal-path PATH         Path to Unreal Engine installation (default: ~/UE_5.6)"
            echo "  -h, --help                 Show this help message"
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
NC='\033[0m' # No Color

echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}COPYING LEARNING AGENTS PYTHON CONTENT${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${YELLOW}Project Path: $PROJECT_PATH${NC}"
echo -e "${YELLOW}Training Build Dir: $TRAINING_BUILD_DIR${NC}"
echo -e "${YELLOW}Unreal Path: $UNREAL_PATH${NC}"

# Source and destination paths
SOURCE_PATH="$UNREAL_PATH/Engine/Plugins/Experimental/LearningAgents/Content/Python"
DEST_PATH="$PROJECT_PATH/$TRAINING_BUILD_DIR/Linux/Engine/Plugins/Experimental/LearningAgents/Content/Python"

echo -e "\n${WHITE}Source Path: $SOURCE_PATH${NC}"
echo -e "${WHITE}Destination Path: $DEST_PATH${NC}"

# Check if source exists
if [ ! -d "$SOURCE_PATH" ]; then
    echo -e "${RED}Source path does not exist: $SOURCE_PATH${NC}"
    echo -e "${RED}Please check your Unreal Engine installation path${NC}"
    exit 1
fi

# Create destination directory structure
DEST_DIR=$(dirname "$DEST_PATH")
if [ ! -d "$DEST_DIR" ]; then
    echo -e "${YELLOW}Creating destination directory: $DEST_DIR${NC}"
    mkdir -p "$DEST_DIR"
fi

# Copy the Python content
echo -e "\n${YELLOW}Copying LearningAgents Python content...${NC}"
if cp -r "$SOURCE_PATH" "$DEST_PATH"; then
    echo -e "${GREEN}Successfully copied LearningAgents Python content!${NC}"
else
    echo -e "${RED}Failed to copy LearningAgents Python content${NC}"
    exit 1
fi

# Verify the copy
if [ -d "$DEST_PATH" ]; then
    FILE_COUNT=$(find "$DEST_PATH" -type f | wc -l)
    echo -e "${GREEN}Verification: $FILE_COUNT files copied to destination${NC}"
else
    echo -e "${RED}Copy verification failed - destination path does not exist${NC}"
    exit 1
fi

echo -e "\n${CYAN}======================================${NC}"
echo -e "${GREEN}COPY COMPLETED SUCCESSFULLY!${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${WHITE}LearningAgents Python content is now available for headless training.${NC}"
