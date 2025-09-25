#!/bin/bash
# Complete Headless Training Setup for FPSGame
# This script provides a complete workflow to set up headless training
# Usage: ./scripts/setup-headless-training.sh [--skip-build] [--skip-package]

# Default values
SKIP_BUILD=false
SKIP_PACKAGE=false
PROJECT_PATH="$(pwd)"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-package)
            SKIP_PACKAGE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--skip-build] [--skip-package]"
            echo "  --skip-build     Skip the build step"
            echo "  --skip-package   Skip the packaging step"
            echo "  -h, --help       Show this help message"
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
echo -e "${GREEN}FPSGAME HEADLESS TRAINING SETUP${NC}"
echo -e "${CYAN}======================================${NC}"

echo -e "${YELLOW}This script will guide you through setting up headless training for FPSGame.${NC}"
echo -e "${YELLOW}Please ensure you have configured your SCharacterManager blueprint first!${NC}"

# Step 1: Build the project (optional)
if [ "$SKIP_BUILD" = false ]; then
    echo -e "\n${GREEN}[1/4] Building project...${NC}"
    if ! "$PROJECT_PATH/scripts/build-local.sh"; then
        echo -e "${RED}Build failed. Please fix build errors before continuing.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Build completed successfully${NC}"
else
    echo -e "${YELLOW}[1/4] Skipping build step${NC}"
fi

# Step 2: Package for training (optional)
if [ "$SKIP_PACKAGE" = false ]; then
    echo -e "\n${GREEN}[2/4] Creating training build...${NC}"
    if ! "$PROJECT_PATH/scripts/package-training.sh"; then
        echo -e "${RED}Packaging failed. Please check the packaging logs.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Training build created successfully${NC}"
    
    # Note: Python content copying is now handled automatically by package-training.sh
    echo -e "${GREEN}LearningAgents Python content copied automatically${NC}"
else
    echo -e "${YELLOW}[2/4] Skipping packaging step${NC}"
    echo -e "${YELLOW}Note: If you're using an existing training build, make sure LearningAgents Python content is copied${NC}"
    echo -e "${YELLOW}You can run: ./scripts/copy-learning-agents-python.sh${NC}"
fi

# Step 3: Verify TensorBoard availability
echo -e "\n${GREEN}[3/5] Verifying TensorBoard availability...${NC}"
PYTHON_EXE="$PROJECT_PATH/Intermediate/PipInstall/bin/python"
TENSORBOARD_EXE="$PROJECT_PATH/Intermediate/PipInstall/bin/tensorboard"

if [ -f "$PYTHON_EXE" ]; then
    echo -e "${GREEN}✓ Learning Agents Python environment found${NC}"
else
    echo -e "${YELLOW}⚠ Learning Agents Python environment not found${NC}"
    echo -e "${GRAY}This may indicate that the build step failed to install dependencies${NC}"
fi

if [ -f "$TENSORBOARD_EXE" ]; then
    echo -e "${GREEN}✓ TensorBoard is available${NC}"
else
    echo -e "${YELLOW}⚠ TensorBoard not found, but this should be installed automatically${NC}"
    echo -e "${GRAY}TensorBoard should be available after Learning Agents dependencies are installed${NC}"
fi

# Step 4: Provide configuration guidance
echo -e "\n${GREEN}[4/5] Configuration Check${NC}"
echo -e "${CYAN}======================================${NC}"

echo -e "${YELLOW}Please verify the following configuration in Unreal Editor:${NC}"

echo -e "\n${CYAN}SCharacterManager Configuration:${NC}"
echo -e "${WHITE}  - Run Mode: Any mode (will auto-force to Training in headless)${NC}"
echo -e "${WHITE}  - All four neural networks assigned:${NC}"
echo -e "${GRAY}     - Encoder Neural Network${NC}"
echo -e "${GRAY}     - Policy Neural Network${NC}"
echo -e "${GRAY}     - Decoder Neural Network${NC}"
echo -e "${GRAY}     - Critic Neural Network${NC}"
echo -e "${WHITE}  - Target Actor reference set${NC}"

echo -e "\n${CYAN}Trainer Training Settings:${NC}"
echo -e "${WHITE}  - Use Tensorboard = True${NC}"
echo -e "${WHITE}  - Save Snapshots = True${NC}"

echo -e "\n${CYAN}Trainer Path Settings:${NC}"
echo -e "${WHITE}  - Non Editor Engine Relative Path configured${NC}"
echo -e "${WHITE}  - Non Editor Intermediate Relative Path configured${NC}"
echo -e "${GRAY}     (Check the package-training.sh output for these paths)${NC}"

echo -e "\n${CYAN}Training Map (P_LearningAgentsTrial):${NC}"
echo -e "${WHITE}  - SCharacter instances placed${NC}"
echo -e "${WHITE}  - STargetActor placed${NC}"
echo -e "${WHITE}  - SCharacterManager placed and configured${NC}"

echo -e "\n${YELLOW}Have you completed all the above configuration? (y/N)${NC}"
read -r confirmation
if [[ ! $confirmation =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}Please complete the configuration in Unreal Editor first.${NC}"
    echo -e "${CYAN}Refer to docs/headless-training-setup.md for detailed instructions.${NC}"
    CONFIG_COMPLETE=false
else
    CONFIG_COMPLETE=true
fi

# Step 5: Ready to train
echo -e "\n${GREEN}[5/5] Training Setup Complete${NC}"
echo -e "${CYAN}======================================${NC}"

if [ "$CONFIG_COMPLETE" = true ]; then
    echo -e "${GREEN}Setup completed successfully!${NC}"
    echo -e "\n${CYAN}You can now start headless training with:${NC}"
    echo -e "${WHITE}  ./scripts/run-training-headless.sh${NC}"
    
    echo -e "\n${CYAN}Optional monitoring commands:${NC}"
    echo -e "${GRAY}  # Start TensorBoard (in another terminal)${NC}"
    echo -e "${WHITE}  ./scripts/run-tensorboard.sh${NC}"
    echo -e "${GRAY}  # TensorBoard will be available at: http://localhost:6006${NC}"
    echo -e "\n${GRAY}  # Monitor training logs (in another terminal)${NC}"
    echo -e "${WHITE}  cd TrainingBuild/Linux/FPSGame/Binaries/Linux${NC}"
    echo -e "${WHITE}  tail -f scharacter_training.log${NC}"
    
    echo -e "\n${YELLOW}Would you like to start training now? (y/N)${NC}"
    read -r start_training
    if [[ $start_training =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Starting headless training...${NC}"
        "$PROJECT_PATH/scripts/run-training-headless.sh"
    fi
else
    echo -e "${YELLOW}Configuration incomplete. Please complete the setup first.${NC}"
fi

echo -e "\n${CYAN}For detailed information, see:${NC}"
echo -e "${WHITE}  - docs/headless-training-setup.md${NC}"
echo -e "${WHITE}  - docs/learning-agents-setup.md${NC}"

