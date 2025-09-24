#!/bin/bash
# Make all shell scripts executable
# This script should be run on Linux after copying the scripts

echo "Making shell scripts executable..."

# Make all .sh files in the scripts directory executable
chmod +x *.sh

echo "Shell scripts are now executable!"
echo ""
echo "Available scripts:"
ls -la *.sh
