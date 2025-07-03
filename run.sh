#!/bin/bash

# Film Industry Platform Run Script for Unix/Linux/macOS
# This script handles scraping, seeding, and running the application

set -e  # Exit immediately if a command exits with a non-zero status.

# --- Color and Formatting Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
NC='\033[0m' # No Color

# Emojis and formatting
STEP_EMOJI="🔧"
SUCCESS_EMOJI="✅"
WARNING_EMOJI="⚠️"
ERROR_EMOJI="❌"
INFO_EMOJI="ℹ️"
PROGRESS_EMOJI="⏳"

# --- Helper Functions ---
print_step() {
    echo -e "${BLUE}${STEP_EMOJI} [$1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}${SUCCESS_EMOJI} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING_EMOJI} WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}${ERROR_EMOJI} ERROR: $1${NC}" >&2 # Send errors to stderr
}

print_info() {
    echo -e "${CYAN}${INFO_EMOJI} INFO: $1${NC}"
}

print_progress() {
    echo -e "${MAGENTA}${PROGRESS_EMOJI} $1${NC}"
}

# --- Parse command line arguments ---
SKIP_SCRAPING=false
SKIP_SEEDING=false
START_SERVER=false

# Iterate through arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
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

# --- Main Script Logic ---
main() {
    # Step 1: Check if project is set up
    print_step 1 "Checking if project is set up..."

    if [[ ! -d "node_modules" ]]; then
        print_error "Node modules not found. Please run setup.sh first."
        return 1 # Return 1 for failure
    fi

    if [[ ! -f ".env" ]]; then
        print_error ".env file not found. Please run setup.sh first."
        return 1
    fi

    print_success "Project appears to be set up!"

    # Step 2: Run scraping (unless skipped)
    if [[ "$SKIP_SCRAPING" = false ]]; then
        print_step 2 "Running film industry data scraping..."
        print_info "This will scrape job listings and professional profiles from film industry websites"
        print_info "The scraping process may take a few minutes..."
        echo

        print_info "Starting Python scraper..."
        local scraper_exit_code=0
        if command -v uv >/dev/null 2>&1; then
            uv run python scraper.py || scraper_exit_code=$?
        else
            python3 scraper.py || scraper_exit_code=$?
        fi

        if [[ "$scraper_exit_code" -ne 0 ]]; then
            print_error "Scraping failed!"
            print_warning "The scraper might have encountered rate limiting or website changes."
            print_info "Don't worry - the scraper includes fallback data generation."
            print_info "Continuing with seeding process..."
        else
            print_success "Scraping completed successfully!"
        fi

        # Check if data file was created
        if [[ -f "film_industry_data.json" ]]; then
            # Using portable way to get file size (might differ slightly from stat -c%s on Linux for very large files)
            # For macOS, 'stat -f%z' is needed. This combines them.
            if [[ "$(uname)" == "Darwin" ]]; then
                FILESIZE=$(stat -f%z "film_industry_data.json")
            else # Assume Linux/WSL
                FILESIZE=$(stat -c%s "film_industry_data.json")
            fi
            # Format with commas for readability (requires printf, not all shells have it)
            printf -v formatted_filesize "%'d" "$FILESIZE"
            print_success "Data file created: film_industry_data.json (${formatted_filesize} bytes)"
        else
            print_error "Data file not created. Please check the scraper output."
            return 1
        fi
    else
        print_info "Skipping scraping step..."
        if [[ ! -f "film_industry_data.json" ]]; then
            print_error "No data file found and scraping was skipped. Please run scraping first."
            return 1
        fi
    fi

    # Step 3: Run database seeding (unless skipped)
    if [[ "$SKIP_SEEDING" = false ]]; then
        print_step 3 "Seeding database with scraped data..."
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
            return 1
        else
            print_success "Database seeding completed successfully!"
        fi
    else
        print_info "Skipping database seeding step..."
    fi

    # Step 4: Start development server (if requested)
    if [[ "$START_SERVER" = true ]]; then
        print_step 4 "Starting development server..."
        print_info "The development server will start at http://localhost:3000"
        print_info "Press Ctrl+C to stop the server"
        echo
        print_info "Starting Next.js development server..."
        npm run dev
        # Note: npm run dev is a blocking process, script execution stops here until Ctrl+C
    fi

    # Final success message
    echo
    echo -e "${GREEN}========================================"
    echo -e "  Process Complete!"
    echo -e "========================================${NC}"
    echo

    if [[ "$START_SERVER" = false ]]; then
        echo -e "${CYAN}Your film industry job board is ready!${NC}"
        echo
        echo -e "${LIGHT_GRAY}To start the development server, run:${NC}"
        echo -e "${DARK_GRAY}  npm run dev${NC}"
        echo
        echo -e "${LIGHT_GRAY}Or run this script with --start-server flag:${NC}"
        echo -e "${DARK_GRAY}  ./run.sh --start-server${NC}"
        echo
    fi

    echo -e "${CYAN}Available command line options:${NC}"
    echo -e "${DARK_GRAY}  --skip-scraping   Skip the data scraping step${NC}"
    echo -e "${DARK_GRAY}  --skip-seeding    Skip the database seeding step${NC}"
    echo -e "${DARK_GRAY}  --start-server    Start the development server after completion${NC}"
    echo -e "${DARK_GRAY}  --help, -h        Show this help message${NC}"

    return 0 # Indicate success
}

# --- Error Handling (mimicking try/catch) ---
main_exit_code=0
main "$@" || main_exit_code=$? # Run main function and capture its exit code

if [[ "$main_exit_code" -ne 0 ]]; then
    print_error "Process failed. See messages above for details."
    echo ""
    print_warning "Troubleshooting:"
    print_info "1. Make sure you ran setup.sh first"
    print_info "2. Check your .env file configuration"
    print_info "3. Verify your database is running and accessible"
    print_info "4. Try running individual commands manually:"
    print_info "   - uv run python scraper.py"
    print_info "   - node prisma/seed-from-json.js"
fi

exit "$main_exit_code"