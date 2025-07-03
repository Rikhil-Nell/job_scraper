# Film Industry Job Board

A cross-platform platform to scrape film industry job listings and professional profiles, seed a database, and provide a web interface for job seekers and recruiters.

---

## Overview

This project scrapes film industry job listings and professional profiles, seeds a database, and provides a web interface for job seekers and recruiters. It supports both Windows (PowerShell) and Unix-like systems (Bash).

---

## Directory Structure

```
.
├── run.sh                  # Main run script for Unix/Linux/macOS
├── run.ps1                 # Main run script for Windows (PowerShell)
├── setup.sh                # Setup script for Unix/Linux/macOS
├── setup.ps1               # Setup script for Windows (PowerShell)
├── scraper.py              # Python script for scraping film industry data
├── prisma/                 # Prisma database folder
│   ├── schema.prisma       # Prisma schema for the database
│   └── seed-from-json.js   # Node.js script to seed the database from scraped data
├── .env                    # Environment variables (created from .env.example)
├── package.json            # Node.js dependencies and scripts
```

---

## Setup Instructions

### Prerequisites

- [Node.js](https://nodejs.org/)
- [Python 3](https://python.org/)
- [uv (Python package manager)](https://docs.astral.sh/uv/getting-started/installation/)
- [Git](https://git-scm.com/)

### Steps

1. **Clone the repository** and navigate to the project directory.
2. **Run the setup script for your platform:**
    - On Unix/Linux/macOS:  
      ```sh
      ./setup.sh
      ```
    - On Windows:  
      ```powershell
      .\setup.ps1
      ```
3. The setup script will:
    - Check for required tools
    - Install Python and Node.js dependencies
    - Set up the `.env` file (from `.env.example` if needed)
    - Set up the database using Prisma (migrations and client generation)
    - Create necessary directories

4. **Configure your `.env` file** with the correct database credentials and settings if needed.

---

## Usage

To run scraping, seeding, and (optionally) start the development server:

- On Unix/Linux/macOS:  
  ```sh
  ./run.sh [OPTIONS]
  ```
- On Windows:  
  ```powershell
  .\run.ps1 [OPTIONS]
  ```

### Options

- `--skip-scraping` &nbsp; Skip the data scraping step
- `--skip-seeding` &nbsp; Skip the database seeding step
- `--start-server` &nbsp; Start the development server after completion
- `--help`, `-h` &nbsp; Show help message

### Typical Workflow

1. Run the setup script (once per environment or after dependency changes)
2. Run `run.sh` or `run.ps1` to scrape data and seed the database
3. Start the development server with `--start-server` or by running:
    ```sh
    npm run dev
    ```

---

## Troubleshooting

- **Missing `node_modules` or `.env`?**  
  Run the setup script first.
- **Scraping fails?**  
  Check your Python installation and dependencies.
- **Seeding fails?**  
  Verify your database connection and configuration in `.env`.

### Run Individual Steps Manually

```sh
uv run python scraper.py
node seed-from-json.js
npm run dev
```

---

## Project Scripts

| Script/File                | Purpose                                                      |
|----------------------------|-------------------------------------------------------------|
| `setup.sh` / `setup.ps1`   | Installs dependencies, sets up environment, prepares database|
| `run.sh` / `run.ps1`       | Checks setup, runs scraper, seeds database, starts server   |
| `scraper.py`               | Scrapes job and professional data, outputs JSON             |
| `prisma/seed-from-json.js` | Seeds the database using the scraped JSON data              |

---

## Data Flow

1. `scraper.py` scrapes job listings and professional profiles, saving them to `film_industry_data.json`.
2. `seed-from-json.js` reads the JSON file and populates the database with countries, cities, users, job posts, skills, and applications.
3. The web application (`npm run dev`) serves the job board interface.

---

## Support

- For setup issues, check the output of the setup script for missing dependencies.
- For database issues, ensure your database is running and accessible as configured in `.env`.
- For scraping issues, ensure Python dependencies are installed and the target websites are accessible.
