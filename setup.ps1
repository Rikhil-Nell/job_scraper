# Film Industry Job Board - Windows Setup Script
# This script sets up the entire project from scratch

param(
    [switch]$SkipConfirmation
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Film Industry Job Board - Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if command exists
function Test-Command {
    param($CommandName)
    $null = Get-Command $CommandName -ErrorAction SilentlyContinue
    return $?
}

# Function to print step
function Write-Step {
    param($StepNumber, $Description)
    Write-Host "[$StepNumber] $Description" -ForegroundColor Green
}

# Function to print error
function Write-ErrorMsg {
    param($Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

# Function to print warning
function Write-WarningMsg {
    param($Message)
    Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

# Function to print success
function Write-Success {
    param($Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor Green
}

# Function to run command safely
function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string[]]$Arguments = @(),
        [string]$Description = ""
    )
    
    try {
        if ($Arguments.Count -gt 0) {
            $fullCommand = "$Command $($Arguments -join ' ')"
        } else {
            $fullCommand = $Command
        }
        
        Write-Host "Running: $fullCommand" -ForegroundColor Cyan
        
        # Use cmd /c to ensure compatibility
        $result = cmd /c "$fullCommand 2>&1"
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -ne 0) {
            Write-ErrorMsg "Command failed with exit code $exitCode"
            if ($result) {
                Write-Host "Output: $result" -ForegroundColor Red
            }
            return $false
        }
        
        if ($result) {
            Write-Host "$result" -ForegroundColor Gray
        }
        
        return $true
    }
    catch {
        Write-ErrorMsg "Failed to run command: $($_.Exception.Message)"
        return $false
    }
}

try {
    # Step 1: Check prerequisites
    Write-Step 1 "Checking prerequisites..."
    
    $missingTools = @()
    
    if (-not (Test-Command "python")) {
        $missingTools += "Python (https://python.org/downloads/)"
    }
    
    if (-not (Test-Command "node")) {
        $missingTools += "Node.js (https://nodejs.org/)"
    }
    
    if (-not (Test-Command "uv")) {
        $missingTools += "uv (https://docs.astral.sh/uv/getting-started/installation/)"
    }
    
    if ($missingTools.Count -gt 0) {
        Write-ErrorMsg "Missing required tools:"
        foreach ($tool in $missingTools) {
            Write-Host "  - $tool" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Please install the missing tools and run this script again." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Success "All prerequisites found!"
    
    # Step 2: Check if .env file exists
    Write-Step 2 "Checking environment configuration..."
    
    if (-not (Test-Path ".env")) {
        Write-WarningMsg ".env file not found. Creating from template..."
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Host "Please edit the .env file with your database credentials before continuing." -ForegroundColor Yellow
            Write-Host "Opening .env file..." -ForegroundColor Cyan
            Start-Process notepad.exe ".env"
            
            if (-not $SkipConfirmation) {
                Write-Host ""
                $response = Read-Host "Have you configured the .env file? (y/N)"
                if ($response -ne "y" -and $response -ne "Y") {
                    Write-Host "Please configure the .env file and run this script again." -ForegroundColor Yellow
                    exit 1
                }
            }
        } else {
            Write-ErrorMsg ".env.example file not found. Please create a .env file manually."
            exit 1
        }
    } else {
        Write-Success ".env file found!"
    }
    
    # Step 3: Install Python dependencies
    Write-Step 3 "Installing Python dependencies..."
    
    if (-not (Invoke-SafeCommand "uv" @("sync"))) {
        Write-ErrorMsg "Failed to install Python dependencies"
        exit 1
    }
    Write-Success "Python dependencies installed!"
    
    # Step 4: Install Node.js dependencies
    Write-Step 4 "Installing Node.js dependencies..."
    
    if (-not (Invoke-SafeCommand "npm" @("install"))) {
        Write-ErrorMsg "Failed to install Node.js dependencies"
        exit 1
    }
    Write-Success "Node.js dependencies installed!"
    
    # Step 5: Generate Prisma client
    Write-Step 5 "Generating Prisma client..."
    
    if (-not (Invoke-SafeCommand "npx" @("prisma", "generate"))) {
        Write-ErrorMsg "Failed to generate Prisma client"
        exit 1
    }
    Write-Success "Prisma client generated!"
    
    # Step 6: Run database migrations
    Write-Step 6 "Running database migrations..."
    
    if (-not (Invoke-SafeCommand "npx" @("prisma", "migrate", "dev", "--name", "init"))) {
        Write-WarningMsg "Database migration failed. Please check your database connection."
        Write-Host "You can run 'npx prisma migrate dev' manually after fixing the database connection." -ForegroundColor Yellow
    } else {
        Write-Success "Database migrations completed!"
    }
    
    # Step 7: Setup complete
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run './run.ps1' to start the scraping and seeding process" -ForegroundColor White
    Write-Host "2. Or run individual commands:" -ForegroundColor White
    Write-Host "   - 'uv run python scraper.py' to scrape data" -ForegroundColor Gray
    Write-Host "   - 'node prisma/seed-from-json.js' to seed database" -ForegroundColor Gray
    Write-Host "   - 'npm run dev' to start the development server" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-ErrorMsg "Setup failed: $($_.Exception.Message)"
    exit 1
}