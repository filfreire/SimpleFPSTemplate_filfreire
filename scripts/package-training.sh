#!/bin/bash
# Package script for FPSGame project - TRAINING BUILD
# This creates a Development build suitable for headless training with Learning Agents
# Usage: ./scripts/package-training.sh [--unreal-path PATH] [--target TARGET] [--platform PLATFORM] [--output-dir DIR]

# Default values
UNREAL_PATH=""
PROJECT_PATH="$(pwd)"
PROJECT_NAME="FPSGame.uproject"
TARGET="FPSGame"
PLATFORM="Linux"
CONFIG="Development"  # Development for training, not Shipping
OUTPUT_DIR="TrainingBuild"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unreal-path)
            UNREAL_PATH="$2"
            shift 2
            ;;
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --unreal-path PATH     Path to Unreal Engine installation (default: ~/UE_5.6)"
            echo "  --project-path PATH    Path to project directory (default: current directory)"
            echo "  --project-name NAME    Project file name (default: FPSGame.uproject)"
            echo "  --target TARGET        Target name (default: FPSGame)"
            echo "  --platform PLATFORM   Platform (default: Linux)"
            echo "  --output-dir DIR       Output directory (default: TrainingBuild)"
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

# Helper function to calculate relative path
get_relative_path() {
    local from_path="$1"
    local to_path="$2"
    
    # Convert to absolute paths
    from_path=$(realpath "$from_path")
    to_path=$(realpath "$to_path")
    
    # Find common root
    local common_root=""
    local from_parts=($(echo "$from_path" | tr '/' ' '))
    local to_parts=($(echo "$to_path" | tr '/' ' '))
    
    local min_length=${#from_parts[@]}
    if [ ${#to_parts[@]} -lt $min_length ]; then
        min_length=${#to_parts[@]}
    fi
    
    for ((i=0; i<min_length; i++)); do
        if [ "${from_parts[i]}" = "${to_parts[i]}" ]; then
            common_root="$common_root/${from_parts[i]}"
        else
            break
        fi
    done
    
    # Calculate relative path
    local up_levels=$((${#from_parts[@]} - ${#common_root//\// }))
    local relative_path=""
    
    # Add ".." for each level up
    for ((i=0; i<up_levels; i++)); do
        if [ -n "$relative_path" ]; then
            relative_path="$relative_path/.."
        else
            relative_path=".."
        fi
    done
    
    # Add remaining path components
    local remaining_parts=("${to_parts[@]:${#common_root//\// }}")
    for part in "${remaining_parts[@]}"; do
        if [ -n "$relative_path" ]; then
            relative_path="$relative_path/$part"
        else
            relative_path="$part"
        fi
    done
    
    echo "$relative_path"
}

# Helper function to calculate relative path to Engine
get_relative_path_to_engine() {
    local exe_path="$1"
    local unreal_path="$2"
    
    local unreal_engine_dir="$unreal_path/Engine"
    get_relative_path "$exe_path" "$unreal_engine_dir"
}

# Helper function to calculate relative path to Intermediate
get_relative_path_to_intermediate() {
    local exe_path="$1"
    local project_path="$2"
    
    local intermediate_dir="$project_path/Intermediate"
    get_relative_path "$exe_path" "$intermediate_dir"
}

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
echo -e "${GREEN}Packaging FPSGame TRAINING BUILD${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${YELLOW}Unreal Path: $UNREAL_PATH${NC}"
echo -e "${YELLOW}Project Path: $PROJECT_PATH${NC}"
echo -e "${YELLOW}Project Name: $PROJECT_NAME${NC}"
echo -e "${YELLOW}Target: $TARGET${NC}"
echo -e "${YELLOW}Platform: $PLATFORM${NC}"
echo -e "${YELLOW}Configuration: $CONFIG${NC}"
echo -e "${YELLOW}Output Directory: $OUTPUT_DIR${NC}"

RUN_UAT_SCRIPT="$UNREAL_PATH/Engine/Build/BatchFiles/RunUAT.sh"
PROJECT_FILE="$PROJECT_PATH/$PROJECT_NAME"
PACKAGE_FOLDER="$PROJECT_PATH/$OUTPUT_DIR"

if [ ! -f "$RUN_UAT_SCRIPT" ]; then
    echo -e "${RED}RunUAT script not found at: $RUN_UAT_SCRIPT${NC}"
    echo -e "${RED}Please check your Unreal Engine installation path${NC}"
    exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}Project file not found at: $PROJECT_FILE${NC}"
    echo -e "${RED}Please check your project path and name${NC}"
    exit 1
fi

# Create output directory if it doesn't exist
if [ ! -d "$PACKAGE_FOLDER" ]; then
    mkdir -p "$PACKAGE_FOLDER"
    echo -e "${CYAN}Created output directory: $PACKAGE_FOLDER${NC}"
fi

echo -e "${CYAN}Starting packaging process for training...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"

# Change to project directory
cd "$PROJECT_PATH" || exit 1

# Build the RunUAT command arguments for training build
UAT_ARGS=(
    "BuildCookRun"
    "-project=\"$PROJECT_FILE\""
    "-nop4"
    "-utf8output"
    "-nocompileeditor"
    "-skipbuildeditor"
    "-cook"
    "-project=\"$PROJECT_FILE\""
    "-target=$TARGET"
    "-platform=$PLATFORM"
    "-installed"
    "-stage"
    "-archive"
    "-package"
    "-build"
    "-pak"
    "-compressed"
    "-archivedirectory=\"$PACKAGE_FOLDER\""
    "-clientconfig=$CONFIG"
    "-nocompile"
    "-nocompileuat"
    # Keep debug info for training builds
    # "-nodebuginfo"  # Commented out for training
)

# Execute the packaging command
echo -e "${GRAY}Executing: $RUN_UAT_SCRIPT ${UAT_ARGS[*]}${NC}"
"$RUN_UAT_SCRIPT" "${UAT_ARGS[@]}"

PACKAGE_EXIT_CODE=$?

if [ $PACKAGE_EXIT_CODE -eq 0 ]; then
    echo -e "${CYAN}======================================${NC}"
    echo -e "${GREEN}PACKAGING COMPLETED SUCCESSFULLY!${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}Training build location: $PACKAGE_FOLDER${NC}"
    
    # Copy LearningAgents Python content for headless training
    echo -e "\n${CYAN}Copying LearningAgents Python content...${NC}"
    if "$PROJECT_PATH/scripts/copy-learning-agents-python.sh" --project-path "$PROJECT_PATH" --training-build-dir "$OUTPUT_DIR" --unreal-path "$UNREAL_PATH"; then
        echo -e "${GREEN}LearningAgents Python content copied successfully!${NC}"
    else
        echo -e "${YELLOW}Warning: Failed to copy LearningAgents Python content${NC}"
        echo -e "${YELLOW}You may need to copy it manually for headless training to work${NC}"
    fi
    
    # Try to find the executable
    EXE_FILES=$(find "$PACKAGE_FOLDER" -name "$TARGET" -type f 2>/dev/null)
    if [ -n "$EXE_FILES" ]; then
        echo -e "\n${GREEN}Game executable(s) found:${NC}"
        echo "$EXE_FILES" | while read -r exe; do
            echo -e "${WHITE}  $exe${NC}"
        done
        
        # Calculate relative paths for Non Editor settings
        FIRST_EXE=$(echo "$EXE_FILES" | head -n1)
        EXE_DIR=$(dirname "$FIRST_EXE")
        echo -e "\n${CYAN}======================================${NC}"
        echo -e "${YELLOW}NON EDITOR PATH CONFIGURATION${NC}"
        echo -e "${CYAN}======================================${NC}"
        echo -e "${YELLOW}For your Learning Manager settings, use these relative paths:${NC}"
        
        # Calculate relative path to Engine
        RELATIVE_TO_ENGINE=$(get_relative_path_to_engine "$EXE_DIR" "$UNREAL_PATH")
        echo -e "\n${GREEN}Non Editor Engine Relative Path:${NC}"
        echo -e "${WHITE}  $RELATIVE_TO_ENGINE${NC}"
        
        # Calculate relative path to Intermediate
        RELATIVE_TO_INTERMEDIATE=$(get_relative_path_to_intermediate "$EXE_DIR" "$PROJECT_PATH")
        echo -e "\n${GREEN}Non Editor Intermediate Relative Path:${NC}"
        echo -e "${WHITE}  $RELATIVE_TO_INTERMEDIATE${NC}"
        
        echo -e "\n${CYAN}======================================${NC}"
        echo -e "${YELLOW}NEXT STEPS FOR HEADLESS TRAINING:${NC}"
        echo -e "${CYAN}======================================${NC}"
        echo -e "${WHITE}1. Open the SCharacterManager blueprint${NC}"
        echo -e "${WHITE}2. Set Run Mode to 'Training'${NC}"
        echo -e "${WHITE}3. In Trainer Training Settings:${NC}"
        echo -e "${WHITE}   - Enable Use Tensorboard = True${NC}"
        echo -e "${WHITE}   - Enable Save Snapshots = True${NC}"
        echo -e "${WHITE}4. In Trainer Path Settings, set the paths above${NC}"
        echo -e "${WHITE}5. Use the run-training-headless.sh script to start training${NC}"
    fi
    exit 0
else
    echo -e "${RED}Packaging failed with exit code: $PACKAGE_EXIT_CODE${NC}"
    exit $PACKAGE_EXIT_CODE
fi

