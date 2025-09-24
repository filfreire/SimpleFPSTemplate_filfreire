#!/bin/bash
# Build script for FPSGame project using RunUAT
# Usage: ./scripts/build-local.sh

# Default values
UNREAL_PATH=""
PROJECT_PATH="$(pwd)"
PROJECT_NAME="FPSGame.uproject"
BUILD_TYPE="Development"
TARGET_PLATFORM="Linux"
ARCHITECTURE="x64"

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
        --build-type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --platform)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        --architecture)
            ARCHITECTURE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --unreal-path PATH     Path to Unreal Engine installation (default: ~/UE_5.6)"
            echo "  --project-path PATH    Path to project directory (default: current directory)"
            echo "  --project-name NAME    Project file name (default: FPSGame.uproject)"
            echo "  --build-type TYPE      Build type: Development, Debug, Shipping (default: Development)"
            echo "  --platform PLATFORM   Target platform: Linux, Windows, Mac (default: Linux)"
            echo "  --architecture ARCH    Architecture: x64, arm64 (default: x64)"
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
NC='\033[0m' # No Color

echo -e "${GREEN}Building FPSGame project using RunUAT...${NC}"
echo -e "${YELLOW}Unreal Path: $UNREAL_PATH${NC}"
echo -e "${YELLOW}Project Path: $PROJECT_PATH${NC}"
echo -e "${YELLOW}Project Name: $PROJECT_NAME${NC}"
echo -e "${YELLOW}Build Type: $BUILD_TYPE${NC}"
echo -e "${YELLOW}Platform: $TARGET_PLATFORM${NC}"
echo -e "${YELLOW}Architecture: $ARCHITECTURE${NC}"

RUNUAT_SCRIPT="$UNREAL_PATH/Engine/Build/BatchFiles/RunUAT.sh"
PROJECT_FILE="$PROJECT_PATH/$PROJECT_NAME"

if [ ! -f "$RUNUAT_SCRIPT" ]; then
    echo -e "${RED}RunUAT script not found at: $RUNUAT_SCRIPT${NC}"
    echo -e "${RED}Please check your Unreal Engine installation path${NC}"
    exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}Project file not found at: $PROJECT_FILE${NC}"
    echo -e "${RED}Please check your project path and name${NC}"
    exit 1
fi

echo -e "${CYAN}Starting build process with RunUAT...${NC}"

# Change to project directory
cd "$PROJECT_PATH" || exit 1

# Run the build command using RunUAT
"$RUNUAT_SCRIPT" BuildCookRun \
    -Build \
    -Cook \
    -Stage \
    -Package \
    -Project="$PROJECT_FILE" \
    -TargetPlatform="$TARGET_PLATFORM" \
    -Architecture="$ARCHITECTURE" \
    -Configuration="$BUILD_TYPE" \
    -SkipEditorContent

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}Build completed successfully!${NC}"
    exit 0
else
    echo -e "${RED}Build failed with exit code: $BUILD_EXIT_CODE${NC}"
    exit $BUILD_EXIT_CODE
fi
