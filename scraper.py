import requests
import json
import time
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
import pandas as pd
import random
from datetime import datetime, timedelta

class FilmIndustryDataScraper:
    def __init__(self):
        self.chrome_options = Options()
        self.chrome_options.add_argument("--headless")
        self.chrome_options.add_argument("--no-sandbox")
        self.chrome_options.add_argument("--disable-dev-shm-usage")
        self.chrome_options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        
        self.film_locations = {
            'United States': ['Los Angeles', 'New York', 'Atlanta', 'Chicago', 'Austin', 'San Francisco'],
            'India': ['Mumbai', 'Chennai', 'Hyderabad', 'Kolkata', 'Pune', 'Bangalore'],
            'United Kingdom': ['London', 'Manchester', 'Glasgow', 'Cardiff'],
            'France': ['Paris', 'Cannes', 'Lyon'],
            'Germany': ['Berlin', 'Munich', 'Hamburg'],
            'Italy': ['Rome', 'Milan', 'Venice'],
            'Spain': ['Madrid', 'Barcelona', 'Valencia'],
            'Canada': ['Toronto', 'Vancouver', 'Montreal']
        }
        
        self.film_categories = [
            'Director', 'Producer', 'Cinematographer', 'Editor', 'Sound Designer',
            'Production Designer', 'Costume Designer', 'Makeup Artist', 'Visual Effects',
            'Screenwriter', 'Casting Director', 'Location Manager', 'Script Supervisor',
            'Gaffer', 'Grip', 'Boom Operator', 'Assistant Director', 'Stunt Coordinator'
        ]
        
        self.film_skills = [
            'Final Cut Pro', 'Avid Media Composer', 'Adobe Premiere Pro', 'After Effects',
            'Cinema 4D', 'Maya', 'Blender', 'Pro Tools', 'Logic Pro', 'RED Camera',
            'ARRI Alexa', 'Steadicam', 'Drone Operation', 'Color Grading', 'Foley',
            'Motion Graphics', 'Storyboarding', 'Script Analysis', 'Budgeting'
        ]

    def scrape_film_jobs(self):
        """Scrape film industry jobs from multiple sources"""
        jobs = []
        
        # Scrape from ProductionHUB
        jobs.extend(self.scrape_production_hub())
        
        # Scrape from FilmJobs.com
        jobs.extend(self.scrape_film_jobs_com())
        
        # Scrape from Mandy Network
        jobs.extend(self.scrape_mandy_network())
        
        # Add fallback data if scraping fails
        if not jobs:
            jobs = self.generate_fallback_jobs()
            
        return jobs

    def scrape_production_hub(self):
        """Scrape jobs from ProductionHUB"""
        jobs = []
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            
            # Note: You'll need to inspect the actual site structure
            response = requests.get('https://www.productionhub.com/jobs', headers=headers)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Adapt these selectors based on actual site structure
            for job_element in soup.find_all('div', class_='job-listing')[:20]:  # Limit to 20 jobs
                try:
                    title = job_element.find('h3', class_='job-title')
                    description = job_element.find('div', class_='job-description')
                    location = job_element.find('span', class_='location')
                    
                    if title and description:
                        jobs.append({
                            'title': title.get_text(strip=True),
                            'description': description.get_text(strip=True)[:500],  # Limit description
                            'location': location.get_text(strip=True) if location else 'Remote',
                            'source': 'ProductionHUB'
                        })
                except Exception as e:
                    print(f"Error parsing job: {e}")
                    continue
                    
        except Exception as e:
            print(f"Error scraping ProductionHUB: {e}")
            
        return jobs

    def scrape_film_jobs_com(self):
        """Scrape jobs from FilmJobs.com"""
        jobs = []
        try:
            driver = webdriver.Chrome(options=self.chrome_options)
            driver.get('https://www.filmjobs.com')
            
            # Wait for page to load
            time.sleep(3)
            
            # Find job listings (adapt selectors based on actual site)
            job_elements = driver.find_elements(By.CSS_SELECTOR, '.job-item')
            
            for job_element in job_elements[:15]:  # Limit to 15 jobs
                try:
                    title = job_element.find_element(By.CSS_SELECTOR, '.job-title').text
                    description = job_element.find_element(By.CSS_SELECTOR, '.job-description').text
                    location = job_element.find_element(By.CSS_SELECTOR, '.job-location').text
                    
                    jobs.append({
                        'title': title,
                        'description': description[:500],
                        'location': location,
                        'source': 'FilmJobs.com'
                    })
                except Exception as e:
                    print(f"Error parsing job: {e}")
                    continue
                    
            driver.quit()
            
        except Exception as e:
            print(f"Error scraping FilmJobs.com: {e}")
            
        return jobs

    def scrape_mandy_network(self):
        """Scrape jobs from Mandy Network"""
        jobs = []
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            
            # Mandy Network job search
            response = requests.get('https://www.mandy.com/jobs', headers=headers)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Adapt selectors based on actual site structure
            for job_element in soup.find_all('div', class_='job-card')[:10]:
                try:
                    title = job_element.find('h2', class_='job-title')
                    description = job_element.find('div', class_='job-summary')
                    location = job_element.find('span', class_='location')
                    
                    if title and description:
                        jobs.append({
                            'title': title.get_text(strip=True),
                            'description': description.get_text(strip=True)[:500],
                            'location': location.get_text(strip=True) if location else 'Remote',
                            'source': 'Mandy Network'
                        })
                except Exception as e:
                    print(f"Error parsing job: {e}")
                    continue
                    
        except Exception as e:
            print(f"Error scraping Mandy Network: {e}")
            
        return jobs

    def generate_fallback_jobs(self):
        """Generate realistic film industry job data if scraping fails"""
        job_titles = [
            'Senior Video Editor - Netflix Original Series',
            'Director of Photography - Independent Film',
            'VFX Supervisor - Marvel Studios',
            'Sound Designer - A24 Horror Film',
            'Production Designer - HBO Max Series',
            'Cinematographer - Documentary Film',
            'Assistant Director - Warner Bros Feature',
            'Makeup Department Head - Disney+ Fantasy',
            'Gaffer - Apple TV+ Drama Series',
            'Script Supervisor - Amazon Prime Thriller',
            'Casting Director - Indie Romance Film',
            'Location Manager - Netflix Action Series',
            'Stunt Coordinator - Fast & Furious Franchise',
            'Costume Designer - Period Drama Film',
            'Boom Operator - Sitcom Production'
        ]
        
        job_descriptions = [
            'Seeking experienced editor for high-profile streaming series. Must have extensive experience with Avid Media Composer and collaborative post-production workflows.',
            'Looking for skilled cinematographer to shoot independent feature film. RED camera experience and natural lighting expertise required.',
            'VFX Supervisor needed for major superhero film. Strong background in Maya, Nuke, and team management essential.',
            'Sound designer for atmospheric horror film. Experience with Pro Tools, Foley recording, and sound library management preferred.',
            'Production designer for fantasy series set in medieval times. Strong attention to historical detail and large-scale set design required.',
            'Cinematographer for environmental documentary. Drone operation license and wildlife filming experience preferred.',
            'Assistant director for big-budget action film. Strong organizational skills and high-pressure set experience required.',
            'Makeup department head for fantasy series. Prosthetics, special effects makeup, and team leadership experience needed.',
            'Gaffer for critically acclaimed drama series. LED lighting expertise and color temperature mastery required.',
            'Script supervisor for psychological thriller. Continuity experience and meticulous attention to detail essential.',
            'Casting director for romantic comedy film. Strong industry connections and talent evaluation skills required.',
            'Location manager for action series. Scouting experience and permit negotiation skills essential.',
            'Stunt coordinator for major action franchise. Safety certification and wire work experience required.',
            'Costume designer for 1940s period drama. Historical research skills and fabric knowledge essential.',
            'Boom operator for multi-camera sitcom. Live audience experience and microphone technique expertise required.'
        ]
        
        jobs = []
        for i, title in enumerate(job_titles):
            location = random.choice([city for cities in self.film_locations.values() for city in cities])
            jobs.append({
                'title': title,
                'description': job_descriptions[i % len(job_descriptions)],
                'location': location,
                'source': 'Generated'
            })
            
        return jobs

    def scrape_film_professionals(self):
        """Scrape film professional profiles"""
        professionals = []
        
        # Try to scrape from IMDb Pro (requires subscription)
        # For demo purposes, we'll generate realistic data
        
        first_names = [
            'Christopher', 'Jennifer', 'Michael', 'Sarah', 'David', 'Emma', 'Robert', 'Lisa',
            'James', 'Amanda', 'Daniel', 'Rachel', 'Matthew', 'Jessica', 'Andrew', 'Emily',
            'Ryan', 'Ashley', 'Kevin', 'Michelle', 'Brian', 'Nicole', 'John', 'Stephanie'
        ]
        
        last_names = [
            'Anderson', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
            'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
            'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson'
        ]
        
        film_bios = [
            'Award-winning filmmaker with over 15 years of experience in documentary and narrative film production.',
            'Experienced cinematographer specializing in natural light photography and handheld camera work.',
            'Post-production specialist with expertise in color grading, sound design, and visual effects.',
            'Creative producer with a proven track record of successful independent film projects.',
            'Visual effects artist with experience in both practical effects and digital compositing.',
            'Screenwriter focused on character-driven narratives and contemporary social issues.',
            'Production designer with extensive experience in period films and television series.',
            'Sound engineer specializing in location recording and post-production audio mixing.'
        ]
        
        for i in range(100):
            professional = {
                'firstName': random.choice(first_names),
                'lastName': random.choice(last_names),
                'role': random.choice(self.film_categories),
                'bio': random.choice(film_bios),
                'skills': random.sample(self.film_skills, random.randint(3, 8)),
                'experience': self.generate_film_experience(),
                'location': random.choice([city for cities in self.film_locations.values() for city in cities])
            }
            professionals.append(professional)
            
        return professionals

    def generate_film_experience(self):
        """Generate realistic film industry experience"""
        experiences = [
            'Lead Editor - "Midnight Stories" (2023)',
            'Director of Photography - "Urban Legends" (2022)',
            'VFX Supervisor - "Digital Dreams" (2023)',
            'Sound Designer - "Whispers in the Dark" (2022)',
            'Production Designer - "The Last Dance" (2023)',
            'Assistant Director - "City Lights" TV Series (2021-2023)',
            'Makeup Artist - "Fantasy Realm" (2022)',
            'Gaffer - "Commercial Campaign" (2023)',
            'Script Supervisor - "Detective Stories" (2022)',
            'Casting Director - "Love in the City" (2023)'
        ]
        return random.choice(experiences)

    def save_to_json(self, jobs, professionals, filename='film_industry_data.json'):
        """Save scraped data to JSON file"""
        data = {
            'jobs': jobs,
            'professionals': professionals,
            'locations': self.film_locations,
            'categories': self.film_categories,
            'skills': self.film_skills,
            'scraped_at': datetime.now().isoformat()
        }
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"Data saved to {filename}")

    def run_scraper(self):
        """Main scraping function"""
        print("Starting film industry data scraping...")
        
        # Scrape jobs
        print("Scraping film industry jobs...")
        jobs = self.scrape_film_jobs()
        print(f"Scraped {len(jobs)} jobs")
        
        # Scrape professionals
        print("Generating film professional profiles...")
        professionals = self.scrape_film_professionals()
        print(f"Generated {len(professionals)} professional profiles")
        
        # Save to JSON
        self.save_to_json(jobs, professionals)
        
        return jobs, professionals

if __name__ == "__main__":
    scraper = FilmIndustryDataScraper()
    jobs, professionals = scraper.run_scraper()
    
    # Display sample data
    print("\n=== SAMPLE JOBS ===")
    for i, job in enumerate(jobs[:3]):
        print(f"\nJob {i+1}:")
        print(f"Title: {job['title']}")
        print(f"Location: {job['location']}")
        print(f"Description: {job['description'][:100]}...")
        print(f"Source: {job['source']}")
    
    print("\n=== SAMPLE PROFESSIONALS ===")
    for i, prof in enumerate(professionals[:3]):
        print(f"\nProfessional {i+1}:")
        print(f"Name: {prof['firstName']} {prof['lastName']}")
        print(f"Role: {prof['role']}")
        print(f"Location: {prof['location']}")
        print(f"Bio: {prof['bio'][:100]}...")
        print(f"Skills: {', '.join(prof['skills'][:3])}...")
        print(f"Experience: {prof['experience']}")
    
    print(f"\nTotal jobs scraped: {len(jobs)}")
    print(f"Total professionals generated: {len(professionals)}")
    print("Data saved to film_industry_data.json")
