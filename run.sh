#!/bin/bash

# Film Industry Platform Run Script for Unix/Linux/macOS
# This script handles scraping, seeding, and running the application

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Emoji and formatting
STEP="🔧"
SUCCESS="✅"
WARNING="⚠️"
ERROR="❌"
INFO="ℹ️"
PROGRESS="⏳"

# Helper functions
print_step() {
    echo -e "${BLUE}${STEP} $1${NC}"
}

print_success() {
    echo -e "${GREEN}${SUCCESS} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${