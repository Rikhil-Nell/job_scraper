#!/bin/bash

# Film Industry Platform Setup Script for Unix/Linux/macOS
# This script will set up the entire project from scratch

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
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_error() {
    echo -e "${RED}${ERROR} $1${NC}"
}

print_info() {
    echo -e "${CYAN}${INFO} $1${NC}"
}

print_progress() {
    echo -e "${MAGENTA}${PROGRESS} $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Wait for user input
wait_for_key() {
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
    echo
}

# Parse command line arguments
SKIP_DEPS=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --skip-deps    Skip dependency checks"
            echo "  --verbose, -v  Enable verbose output"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main setup function
main() {
    echo -e "${CYAN}🎬 Film Industry Platform Setup"
    echo -e "==============================${NC}"
    echo "This script will set up your development environment automatically."
    echo

    # Check if running on supported OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        OS="Windows"
    else
        print_warning "Unknown OS type: $OSTYPE"
        OS="Unknown"
    fi

    print_info "Detected OS: $OS"

    # Step 1: Check prerequisites
    print_step "Checking prerequisites..."
    
    missing_tools=()
    
    if ! command_exists node; then
        missing_tools+=("Node.js")
    fi
    
    if ! command_exists python3; then
        missing_tools+=("Python 3")
    fi
    
    if ! command_exists git; then
        missing_tools+=("Git")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]] && [[ "$SKIP_DEPS" == false ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install the following:"
        print_info "- Node.js: https://nodejs.org/"
        print_info "- Python 3: https://python.org/"
        print_info "- Git: https://git-scm.com/"
        
        if [[ "$OS" == "macOS" ]]; then
            print_info "On macOS, you can use Homebrew:"
            print_info "  brew install node python git"
        elif [[ "$OS" == "Linux" ]]; then
            print_info "On Ubuntu/Debian:"
            print_info "  sudo apt update && sudo apt install nodejs npm python3 python3-pip git"
            print_info "On CentOS/RHEL/Fedora:"
            print_info "  sudo yum install nodejs npm python3 python3-pip git"
        fi
        
        print_info "Or use --skip-deps to continue anyway"
        exit 1
    fi
    
    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        print_success "All prerequisites found!"
    fi

    # Step 2: Install uv (Python package manager)
    print_step "Installing uv (Python package manager)..."
    
    if ! command_exists uv; then
        print_info "Installing uv..."
        if command_exists curl; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
        elif command_exists wget; then
            wget -qO- https://astral.sh/uv/install.sh | sh
        else
            print_error "Neither curl nor wget found. Cannot install uv."
            print_info "Please install uv manually from: https://github.com/astral-sh/uv"
            exit 1
        fi
        
        # Source the shell to get uv in PATH
        export PATH="$HOME/.cargo/bin:$PATH"
        
        if command_exists uv; then
            print_success "uv installed successfully"
        else
            print_warning "uv installation may have failed. Please check manually."
        fi
    else
        print_success "uv is already installed"
    fi

    # Step 3: Set up Python virtual environment
    print_step "Setting up Python environment..."
    
    if [[ -d ".venv" ]]; then
        print_info "Virtual environment already exists"
    else
        print_info "Creating virtual environment..."
        if command_exists uv; then
            uv venv
        else
            python3 -m venv .venv
        fi
        print_success "Virtual environment created"
    fi
    
    print_info "Installing Python dependencies..."
    if command_exists uv; then
        uv sync
    else
        source .venv/bin/activate
        pip install -r requirements.txt 2>/dev/null || print_warning "No requirements.txt found"
    fi
    print_success "Python dependencies installed"

    # Step 4: Install Node.js dependencies
    print_step "Installing Node.js dependencies..."
    
    if [[ -f "package.json" ]]; then
        print_info "Installing npm packages..."
        npm install
        print_success "Node.js dependencies installed"
    else
        print_warning "No package.json found, skipping npm install"
    fi

    # Step 5: Set up environment variables
    print_step "Setting up environment variables..."
    
    if [[ ! -f ".env" ]]; then
        print_info "Creating .env file..."
        cat > .env << 'EOF'
# Database Configuration
DATABASE_URL="file:./dev.db"

# JWT Configuration
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"

# Server Configuration
PORT=3000
NODE_ENV=development

# Python Virtual Environment
PYTHON_PATH=".venv/bin/python"
EOF
        print_success ".env file created"
    else
        print_success ".env file already exists"
    fi

    # Step 6: Set up Prisma
    print_step "Setting up Prisma database..."
    
    if [[ -f "prisma/schema.prisma" ]]; then
        print_info "Generating Prisma client..."
        npx prisma generate
        print_success "Prisma client generated"
        
        print_info "Running database migrations..."
        npx prisma migrate dev --name init
        print_success "Database migrations completed"
    else
        print_warning "No Prisma schema found, skipping database setup"
    fi

    # Step 7: Create necessary directories
    print_step "Creating necessary directories..."
    
    directories=("data" "logs" "uploads" "temp")
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        fi
    done

    # Step 8: Set up executable permissions
    print_step "Setting up executable permissions..."
    
    chmod +x setup.sh run.sh 2>/dev/null || true
    print_success "Executable permissions set"

    # Step 9: Final checks
    print_step "Running final checks..."
    
    errors=()
    
    if [[ ! -f ".env" ]]; then
        errors+=("Missing .env file")
    fi
    
    if [[ ! -d "node_modules" ]]; then
        errors+=("Node modules not installed")
    fi
    
    if [[ ! -d ".venv" ]]; then
        errors+=("Python virtual environment not created")
    fi
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        print_error "Setup incomplete. Issues found:"
        for error in "${errors[@]}"; do
            print_error "  - $error"
        done
        exit 1
    fi

    # Success message
    echo
    echo -e "${GREEN}🎉 Setup Complete!"
    echo "=================="
    echo "Your Film Industry Platform is ready to use."
    echo
    echo "Next steps:"
    echo "1. Run: ./run.sh --scrape    # To scrape data and seed database"
    echo "2. Run: ./run.sh --dev       # To start development server"
    echo "3. Run: ./run.sh --help      # To see all available options"
    echo
    echo "Happy coding! 🚀${NC}"
    
    print_info "Setup completed at $(date)"
}

# Error handling
trap 'print_error "Setup failed at line $LINENO. Exit code: $?"' ERR

# Run main function
main "$@"