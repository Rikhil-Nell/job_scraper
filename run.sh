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

# Parse command line arguments
SKIP_SCRAPING=false
SKIP_SEEDING=false
START_SERVER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-scraping)
            SKIP_SCRAPING=true
            shift
            ;;
        --skip-seeding)
            SKIP_SEEDING=true
            shift
            ;;
        --start-server)
            START_SERVER=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./run.sh [OPTIONS]"
            echo "Options:"
            echo "  --skip-scraping   Skip the data scraping step"
            echo "  --skip-seeding    Skip the database seeding step"
            echo "  --start-server    Start the development server after completion"
            echo "  --help, -h        Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}========================================"
echo -e "  Film Industry Job Board - Run"
echo -e "========================================${NC}"
echo

# Step 1: Check if project is set up
print_step "Checking if project is set up..."

if [[ ! -d "node_modules" ]]; then
    print_error "Node modules not found. Please run setup.sh first."
    exit 1
fi

if [[ ! -f ".env" ]]; then
    print_error ".env file not found. Please run setup.sh first."
    exit 1
fi

print_success "Project appears to be set up!"

# Step 2: Run scraping (unless skipped)
if [[ "$SKIP_SCRAPING" = false ]]; then
    print_step "Running film industry data scraping..."
    print_info "This will scrape job listings and professional profiles from film industry websites"
    print_info "The scraping process may take a few minutes..."
    echo

    print_info "Starting Python scraper..."
    if command -v uv >/dev/null 2>&1; then
        uv run python scraper.py || SCRAPER_EXIT=$?
    else
        python3 scraper.py || SCRAPER_EXIT=$?
    fi

    if [[ "${SCRAPER_EXIT:-0}" -ne 0 ]]; then
        print_error "Scraping failed!"
        print_warning "The scraper might have encountered rate limiting or website changes."
        print_info "Don't worry - the scraper includes fallback data generation."
        print_info "Continuing with seeding process..."
    else
        print_success "Scraping completed successfully!"
    fi

    # Check if data file was created
    if [[ -f "film_industry_data.json" ]]; then
        FILESIZE=$(stat -c%s "film_industry_data.json")
        print_success "Data file created: film_industry_data.json ($(printf "%'d" "$FILESIZE") bytes)"
    else
        print_error "Data file not created. Please check the scraper output."
        exit 1
    fi
else
    print_info "Skipping scraping step..."
    if [[ ! -f "film_industry_data.json" ]]; then
        print_error "No data file found and scraping was skipped. Please run scraping first."
        exit 1
    fi
fi

# Step 3: Run database seeding (unless skipped)
if [[ "$SKIP_SEEDING" = false ]]; then
    print_step "Seeding database with scraped data..."
    print_info "This will populate your database with:"
    print_info "  - Film industry professionals"
    print_info "  - Job postings"
    print_info "  - Skills and experience data"
    print_info "  - Geographic locations"
    echo

    print_info "Starting database seeding..."
    node prisma/seed-from-json.js
    if [[ $? -ne 0 ]]; then
        print_error "Database seeding failed!"
        print_warning "Please check your database connection and configuration."
        print_info "You can run 'node prisma/seed-from-json.js' manually after fixing the issue."
        exit 1
    else
        print_success "Database seeding completed successfully!"
    fi
else
    print_info "Skipping database seeding step..."
fi

# Step 4: Start development server (if requested)
if [[ "$START_SERVER" = true ]]; then
    print_step "Starting development server..."
    print_info "The development server will start at http://localhost:3000"
    print_info "Press Ctrl+C to stop the server"
    echo
    print_info "Starting Next.js development server..."
    npm run dev
fi

echo
echo -e "${GREEN}========================================"
echo -e "  Process Complete!"
echo -e "========================================${NC}"
echo

if [[ "$START_SERVER" = false ]]; then
    echo -e "${CYAN}Your film industry job board is ready!${NC}"
    echo
    echo -e "To start the development server, run:"
    echo -e "  npm run dev"
    echo
    echo -e "Or run this script with --start-server flag:"
    echo -e "  ./run.sh --start-server"
    echo
fi

echo -e "${CYAN}Available command line options:${NC}"
echo -e "  --skip-scraping   Skip the data scraping step"
echo -e "  --skip-seeding    Skip the database seeding step"
echo -e "  --start-server    Start the development server after completion"
echo -e "  --help, -h        Show this help message"