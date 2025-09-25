#!/bin/bash
# Training Log Monitor for FPSGame
# This script monitors the training logs in real-time
# Usage: ./scripts/tail-training-logs.sh [--log-file "scharacter_training.log"] [--follow] [--lines 50]

# Default values
PROJECT_PATH="$(pwd)"
TRAINING_BUILD_DIR="TrainingBuild"
LOG_FILE="scharacter_training.log"
FOLLOW=true
LINES=50

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
        --log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        --follow)
            FOLLOW=true
            shift
            ;;
        --no-follow)
            FOLLOW=false
            shift
            ;;
        --lines)
            LINES="$2"
            shift 2
            ;;
        -h|--help)
            echo "======================================"
            echo "FPSGAME TRAINING LOG MONITOR"
            echo "======================================"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --project-path PATH        Project directory path (default: current directory)"
            echo "  --training-build-dir DIR   Training build directory (default: TrainingBuild)"
            echo "  --log-file FILE            Log file to monitor (default: scharacter_training.log)"
            echo "  --follow                   Follow the log file (default: true)"
            echo "  --no-follow               Don't follow the log file"
            echo "  --lines NUMBER            Number of lines to show initially (default: 50)"
            echo "  -h, --help                Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0"
            echo "  $0 --lines 100"
            echo "  $0 --log-file 'my_training.log'"
            echo "  $0 --no-follow"
            echo ""
            echo "Press Ctrl+C to stop monitoring"
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
echo -e "${GREEN}FPSGAME TRAINING LOG MONITOR${NC}"
echo -e "${CYAN}======================================${NC}"

# Find the log file
BUILD_PATH="$PROJECT_PATH/$TRAINING_BUILD_DIR"
LOG_FILES=$(find "$BUILD_PATH" -name "$LOG_FILE" -type f 2>/dev/null)

if [ -z "$LOG_FILES" ]; then
    echo -e "${RED}Log file '$LOG_FILE' not found in build directory: $BUILD_PATH${NC}"
    echo -e "${RED}Available log files:${NC}"
    ALL_LOGS=$(find "$BUILD_PATH" -name "*.log" -type f 2>/dev/null)
    if [ -n "$ALL_LOGS" ]; then
        echo "$ALL_LOGS" | while read -r log; do
            echo -e "${GRAY}  $log${NC}"
        done
    else
        echo -e "${GRAY}  No log files found${NC}"
    fi
    echo -e "${RED}Please check the TrainingBuild directory or specify the correct log file name${NC}"
    exit 1
fi

LOG_FILE_PATH=$(echo "$LOG_FILES" | head -n1)
echo -e "${YELLOW}Monitoring log file: $LOG_FILE_PATH${NC}"
echo -e "${YELLOW}Lines to show: $LINES${NC}"
echo -e "${YELLOW}Follow mode: $FOLLOW${NC}"
echo ""

# Check if log file exists and has content
if [ ! -f "$LOG_FILE_PATH" ]; then
    echo -e "${RED}Log file does not exist: $LOG_FILE_PATH${NC}"
    exit 1
fi

LOG_SIZE=$(stat -c%s "$LOG_FILE_PATH" 2>/dev/null || echo "0")
if [ "$LOG_SIZE" -eq 0 ]; then
    echo -e "${YELLOW}Log file is empty. Waiting for content...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop waiting${NC}"
    echo ""
fi

# Show recent log entries
echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}RECENT LOG ENTRIES${NC}"
echo -e "${CYAN}======================================${NC}"

# Function to handle cleanup on exit
cleanup() {
    echo -e "\n${CYAN}======================================${NC}"
    echo -e "${YELLOW}LOG MONITORING ENDED${NC}"
    echo -e "${CYAN}======================================${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

if [ "$FOLLOW" = true ]; then
    # Show last N lines and then follow
    tail -n "$LINES" -f "$LOG_FILE_PATH"
else
    # Just show last N lines
    tail -n "$LINES" "$LOG_FILE_PATH"
fi

# This should not be reached if following, but just in case
cleanup

