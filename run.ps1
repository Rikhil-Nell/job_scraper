# Film Industry Job Board - Windows Run Script
# This script runs the scraping and seeding process

param(
    [switch]$SkipScraping,
    [switch]$SkipSeeding,
    [switch]$StartServer
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Film Industry Job Board - Run" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to print step
function Write-Step {
    param($StepNumber, $Description)
    Write-Host "[$StepNumber] $Description" -ForegroundColor Green
}

# Function to print error
function Write-Error {
    param($Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

# Function to print warning
function Write-Warning {
    param($Message)
    Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

# Function to print success
function Write-Success {
    param($Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor Green
}

# Function to print info
function Write-Info {
    param($Message)
    Write-Host "INFO: $Message" -ForegroundColor Cyan
}

try {
    # Check if setup was run
    Write-Step 1 "Checking if project is set up..."
    
    if (-not (Test-Path "node_modules")) {
        Write-Error "Node modules not found. Please run setup.ps1 first."
        exit 1
    }
    
    if (-not (Test-Path ".env")) {
        Write-Error ".env file not found. Please run setup.ps1 first."
        exit 1
    }
    
    Write-Success "Project appears to be set up!"
    
    # Step 2: Run scraping (unless skipped)
    if (-not $SkipScraping) {
        Write-Step 2 "Running film industry data scraping..."
        Write-Info "This will scrape job listings and professional profiles from film industry websites"
        Write-Info "The scraping process may take a few minutes..."
        Write-Host ""
        
        Write-Host "Starting Python scraper..." -ForegroundColor Cyan
        $scraperResult = Start-Process -FilePath "uv" -ArgumentList "run", "python", "scraper.py" -NoNewWindow -Wait -PassThru
        
        if ($scraperResult.ExitCode -ne 0) {
            Write-Error "Scraping failed!"
            Write-Warning "The scraper might have encountered rate limiting or website changes."
            Write-Info "Don't worry - the scraper includes fallback data generation."
            Write-Info "Continuing with seeding process..."
        } else {
            Write-Success "Scraping completed successfully!"
        }
        
        # Check if data file was created
        if (Test-Path "film_industry_data.json") {
            $dataFile = Get-Item "film_industry_data.json"
            Write-Success "Data file created: $($dataFile.Name) ($('{0:N0}' -f $dataFile.Length) bytes)"
        } else {
            Write-Error "Data file not created. Please check the scraper output."
            exit 1
        }
    } else {
        Write-Info "Skipping scraping step..."
        if (-not (Test-Path "film_industry_data.json")) {
            Write-Error "No data file found and scraping was skipped. Please run scraping first."
            exit 1
        }
    }
    
    # Step 3: Run database seeding (unless skipped)
    if (-not $SkipSeeding) {
        Write-Step 3 "Seeding database with scraped data..."
        Write-Info "This will populate your database with:"
        Write-Info "  - Film industry professionals"
        Write-Info "  - Job postings"
        Write-Info "  - Skills and experience data"
        Write-Info "  - Geographic locations"
        Write-Host ""
        
        Write-Host "Starting database seeding..." -ForegroundColor Cyan
        $seedResult = Start-Process -FilePath "node" -ArgumentList "prisma/seed-from-json.js" -NoNewWindow -Wait -PassThru
        
        if ($seedResult.ExitCode -ne 0) {
            Write-Error "Database seeding failed!"
            Write-Warning "Please check your database connection and configuration."
            Write-Info "You can run 'node prisma/seed-from-json.js' manually after fixing the issue."
            exit 1
        } else {
            Write-Success "Database seeding completed successfully!"
        }
    } else {
        Write-Info "Skipping database seeding step..."
    }
    
    # Step 4: Start development server (if requested)
    if ($StartServer) {
        Write-Step 4 "Starting development server..."
        Write-Info "The development server will start at http://localhost:3000"
        Write-Info "Press Ctrl+C to stop the server"
        Write-Host ""
        
        Write-Host "Starting Next.js development server..." -ForegroundColor Cyan
        Start-Process -FilePath "npm" -ArgumentList "run", "dev" -NoNewWindow -Wait
    }
    
    # Final success message
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Process Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    if (-not $StartServer) {
        Write-Host "Your film industry job board is ready!" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To start the development server, run:" -ForegroundColor White
        Write-Host "  npm run dev" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Or run this script with -StartServer flag:" -ForegroundColor White
        Write-Host "  .\run.ps1 -StartServer" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Available command line options:" -ForegroundColor Cyan
        Write-Host "  -SkipScraping    Skip the data scraping step" -ForegroundColor Gray
        Write-Host "  -SkipSeeding     Skip the database seeding step" -ForegroundColor Gray
        Write-Host "  -StartServer     Start the development server after completion" -ForegroundColor Gray
    }
    
} catch {
    Write-Error "Process failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure you ran setup.ps1 first" -ForegroundColor Gray
    Write-Host "2. Check your .env file configuration" -ForegroundColor Gray
    Write-Host "3. Verify your database is running and accessible" -ForegroundColor Gray
    Write-Host "4. Try running individual commands manually:" -ForegroundColor Gray
    Write-Host "   - uv run python scraper.py" -ForegroundColor Gray
    Write-Host "   - node prisma/seed-from-json.js" -ForegroundColor Gray
    exit 1
}