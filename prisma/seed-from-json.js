// prisma/seed-from-json.js
const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

// Keep track of used emails to avoid duplicates
const usedEmails = new Set();

async function loadScrapedData() {
  try {
    const dataPath = path.join(__dirname, '..', 'film_industry_data.json');
    const rawData = fs.readFileSync(dataPath, 'utf8');
    return JSON.parse(rawData);
  } catch (error) {
    console.error('Error loading scraped data:', error);
    console.log('Run the Python scraper first to generate film_industry_data.json');
    process.exit(1);
  }
}

function getRandomElement(array) {
  return array[Math.floor(Math.random() * array.length)];
}

function getRandomElements(array, min, max) {
  const count = Math.floor(Math.random() * (max - min + 1)) + min;
  const shuffled = [...array].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

function generateUniqueEmail(firstName, lastName, domain, index = 0) {
  const baseEmail = `${firstName.toLowerCase()}.${lastName.toLowerCase()}${index > 0 ? index : ''}@${domain}.com`;
  
  if (usedEmails.has(baseEmail)) {
    return generateUniqueEmail(firstName, lastName, domain, index + 1);
  }
  
  usedEmails.add(baseEmail);
  return baseEmail;
}

async function main() {
  console.log('Starting film industry database seeding from scraped data...');

  // Load scraped data
  const scrapedData = await loadScrapedData();
  console.log(`Loaded ${scrapedData.jobs.length} jobs and ${scrapedData.professionals.length} professionals`);

  // 1. Clean up existing data
  console.log('Cleaning up database...');
  await prisma.role_permissions.deleteMany({});
  await prisma.job_applications.deleteMany({});
  await prisma.job_posts.deleteMany({});
  await prisma.social_links.deleteMany({});
  await prisma.portfolio_images.deleteMany({});
  await prisma.work_experience.deleteMany({});
  await prisma.youtube_videos.deleteMany({});
  await prisma.skills.deleteMany({});
  await prisma.user_profile.deleteMany({});
  await prisma.user.deleteMany({});
  await prisma.city.deleteMany({});
  await prisma.country.deleteMany({});
  await prisma.currency.deleteMany({});
  await prisma.job_category.deleteMany({});
  await prisma.job_type.deleteMany({});
  await prisma.roles.deleteMany({});
  await prisma.resource.deleteMany({});
  console.log('Database cleaned up.');

  // Clear used emails set since we cleaned the database
  usedEmails.clear();

  // 2. Seed Countries and Cities from scraped data
  console.log('Seeding countries and cities...');
  const countries = [];
  const cities = [];
  
  for (const [countryName, cityNames] of Object.entries(scrapedData.locations)) {
    const country = await prisma.country.create({
      data: { name: countryName }
    });
    countries.push(country);
    
    for (const cityName of cityNames) {
      const city = await prisma.city.create({
        data: {
          name: cityName,
          countryId: country.id
        }
      });
      cities.push(city);
    }
  }
  console.log(`Created ${countries.length} countries and ${cities.length} cities`);

  // 3. Seed Currencies
  const currencyData = [
    { name: 'USD', symbol: '$' },
    { name: 'EUR', symbol: '€' },
    { name: 'GBP', symbol: '£' },
    { name: 'INR', symbol: '₹' },
    { name: 'CAD', symbol: 'C$' }
  ];
  await prisma.currency.createMany({ data: currencyData });
  const currencies = await prisma.currency.findMany();
  console.log(`Created ${currencies.length} currencies`);

  // 4. Seed Job Categories from scraped data
  const jobCategoryData = scrapedData.categories.map(name => ({ name }));
  await prisma.job_category.createMany({ data: jobCategoryData });
  const jobCategories = await prisma.job_category.findMany();
  console.log(`Created ${jobCategories.length} job categories`);

  // 5. Seed Job Types
  const jobTypeData = [
    { name: 'Full-time' },
    { name: 'Contract' },
    { name: 'Freelance' },
    { name: 'Project-based' },
    { name: 'Part-time' }
  ];
  await prisma.job_type.createMany({ data: jobTypeData });
  const jobTypes = await prisma.job_type.findMany();
  console.log(`Created ${jobTypes.length} job types`);

  // 6. Seed Roles
  const roleData = [
    { name: 'ADMIN', description: 'Administrator with all permissions.' },
    { name: 'RECRUITER', description: 'Can post jobs and manage applications.' },
    { name: 'CANDIDATE', description: 'Can apply for jobs and manage their profile.' },
  ];
  await prisma.roles.createMany({ data: roleData });
  const roles = await prisma.roles.findMany();
  console.log(`Created ${roles.length} roles`);

  // 7. Create Users from scraped professionals
  console.log('Creating users from scraped data...');
  const candidateRole = roles.find(r => r.name === 'CANDIDATE');
  const recruiterRole = roles.find(r => r.name === 'RECRUITER');
  const createdUsers = [];

  // Create recruiters (20% of users)
  const recruiterCount = Math.floor(scrapedData.professionals.length * 0.2);
  for (let i = 0; i < recruiterCount; i++) {
    const professional = scrapedData.professionals[i];
    const email = generateUniqueEmail(
      professional.firstName, 
      professional.lastName, 
      getRandomElement(['films', 'studio', 'production', 'entertainment'])
    );
    
    // Find matching city
    let targetCity = cities.find(c => c.name === professional.location);
    if (!targetCity) {
      targetCity = getRandomElement(cities);
    }
    const targetCountry = countries.find(c => c.id === targetCity.countryId);

    try {
      const user = await prisma.user.create({
        data: {
          email,
          password: 'hashedPassword123', // In production, use proper hashing
          role_id: recruiterRole.id,
          is_verified: true,
          user_profile: {
            create: {
              firstName: professional.firstName,
              lastName: professional.lastName,
              avatarUrl: `https://api.dicebear.com/7.x/personas/svg?seed=${professional.firstName}${professional.lastName}`,
              Bio: professional.bio,
              Availability: 'Hiring',
              Website: `https://${professional.firstName.toLowerCase()}${professional.lastName.toLowerCase()}.com`,
              publicEmail: email,
              role: professional.role,
              city_id: targetCity.id,
              country_id: targetCountry.id,
              social_links: {
                create: {
                  linkedin: `https://linkedin.com/in/${professional.firstName.toLowerCase()}-${professional.lastName.toLowerCase()}`,
                  x: `https://x.com/${professional.firstName.toLowerCase()}_${professional.lastName.toLowerCase()}`,
                  instagram: `https://instagram.com/${professional.firstName.toLowerCase()}.${professional.lastName.toLowerCase()}`
                }
              }
            },
          },
        },
        include: {
          user_profile: true,
          role: true,
        },
      });
      createdUsers.push(user);
      console.log(`Created recruiter: ${email}`);
    } catch (error) {
      console.error(`Failed to create recruiter ${email}:`, error.message);
    }
  }

  // Create candidates (80% of users)
  for (let i = recruiterCount; i < scrapedData.professionals.length; i++) {
    const professional = scrapedData.professionals[i];
    const email = generateUniqueEmail(
      professional.firstName, 
      professional.lastName, 
      getRandomElement(['gmail', 'yahoo', 'outlook', 'icloud'])
    );
    
    // Find matching city
    let targetCity = cities.find(c => c.name === professional.location);
    if (!targetCity) {
      targetCity = getRandomElement(cities);
    }
    const targetCountry = countries.find(c => c.id === targetCity.countryId);

    try {
      const user = await prisma.user.create({
        data: {
          email,
          password: 'hashedPassword123',
          role_id: candidateRole.id,
          is_verified: true,
          user_profile: {
            create: {
              firstName: professional.firstName,
              lastName: professional.lastName,
              avatarUrl: `https://api.dicebear.com/7.x/personas/svg?seed=${professional.firstName}${professional.lastName}`,
              Bio: professional.bio,
              Availability: getRandomElement(['Available', 'Busy', 'Between Projects', 'Open to Opportunities']),
              Website: `https://${professional.firstName.toLowerCase()}${professional.lastName.toLowerCase()}.com`,
              publicEmail: email,
              role: professional.role,
              city_id: targetCity.id,
              country_id: targetCountry.id,
              social_links: {
                create: {
                  linkedin: `https://linkedin.com/in/${professional.firstName.toLowerCase()}-${professional.lastName.toLowerCase()}`,
                  x: `https://x.com/${professional.firstName.toLowerCase()}_${professional.lastName.toLowerCase()}`,
                  instagram: `https://instagram.com/${professional.firstName.toLowerCase()}.${professional.lastName.toLowerCase()}`
                }
              }
            },
          },
        },
        include: {
          user_profile: true,
          role: true,
        },
      });
      createdUsers.push(user);
      if (i % 10 === 0) {
        console.log(`Created ${i - recruiterCount + 1} candidates...`);
      }
    } catch (error) {
      console.error(`Failed to create candidate ${email}:`, error.message);
    }
  }

  console.log(`Created ${createdUsers.length} users (${recruiterCount} recruiters, ${createdUsers.length - recruiterCount} candidates)`);

  // 8. Add Skills and Experience to Candidates
  console.log('Adding skills and experience to candidates...');
  const candidateUsers = createdUsers.filter(u => u.role.name === 'CANDIDATE');

  for (let i = 0; i < candidateUsers.length; i++) {
    const user = candidateUsers[i];
    const professionalIndex = i + recruiterCount;
    const professional = scrapedData.professionals[professionalIndex];
    
    if (user.user_profile && professional) {
      // Add skills from scraped data
      const skillsToAdd = professional.skills || getRandomElements(scrapedData.skills, 3, 8);
      try {
        await prisma.skills.createMany({
          data: skillsToAdd.map(skillName => ({
            name: skillName,
            user_profile_id: user.user_profile.id
          }))
        });

        // Add work experience
        const experienceCount = Math.floor(Math.random() * 3) + 1;
        for (let j = 0; j < experienceCount; j++) {
          const experienceYear = 2024 - Math.floor(Math.random() * 10);
          await prisma.work_experience.create({
            data: {
              user_profile_id: user.user_profile.id,
              title: getRandomElement(scrapedData.categories),
              role: professional.experience || `${getRandomElement(scrapedData.categories)} - ${getRandomElement(['Feature Film', 'TV Series', 'Commercial', 'Documentary', 'Short Film'])}`,
              year: experienceYear,
              description: `Professional ${getRandomElement(scrapedData.categories).toLowerCase()} work on various film and television projects.`
            }
          });
        }
      } catch (error) {
        console.error(`Failed to add skills/experience for user ${user.email}:`, error.message);
      }
    }
  }
  console.log(`Added skills and experience to ${candidateUsers.length} candidates`);

  // 9. Create Job Posts from scraped data
  console.log('Creating job posts from scraped data...');
  const recruiterUsers = createdUsers.filter(u => u.role.name === 'RECRUITER');
  const createdJobs = [];

  const maxJobs = Math.min(scrapedData.jobs.length, recruiterUsers.length * 3);
  for (let i = 0; i < maxJobs; i++) {
    const job = scrapedData.jobs[i];
    const recruiter = recruiterUsers[i % recruiterUsers.length];
    
    // Find matching city for job location
    let jobCity = cities.find(c => c.name === job.location);
    if (!jobCity) {
      jobCity = getRandomElement(cities);
    }
    const jobCountry = countries.find(c => c.id === jobCity.countryId);

    // Determine job category based on title
    let jobCategory = jobCategories.find(cat => 
      job.title.toLowerCase().includes(cat.name.toLowerCase())
    );
    if (!jobCategory) {
      jobCategory = getRandomElement(jobCategories);
    }

    // Determine salary range based on location
    const salaryMultiplier = getSalaryMultiplier(jobCountry.name);
    const minSalary = Math.floor((40000 + Math.random() * 40000) * salaryMultiplier);
    const maxSalary = Math.floor(minSalary * (1.2 + Math.random() * 0.8));

    try {
      const jobPost = await prisma.job_posts.create({
        data: {
          user_id: recruiter.id,
          title: job.title,
          description: job.description,
          MinSalary: minSalary,
          MaxSalary: maxSalary,
          IsAccepting: true,
          currency_id: getCurrencyForCountry(currencies, jobCountry.name),
          job_type_id: getRandomElement(jobTypes).id,
          category_id: jobCategory.id,
          city_id: jobCity.id,
          country_id: jobCountry.id,
        },
      });
      createdJobs.push(jobPost);
      if (i % 10 === 0) {
        console.log(`Created ${i + 1} job posts...`);
      }
    } catch (error) {
      console.error(`Failed to create job post "${job.title}":`, error.message);
    }
  }

  console.log(`Created ${createdJobs.length} job posts from scraped data`);

  // 10. Create Job Applications
  console.log('Creating job applications...');
  const applications = [];
  
  for (const candidate of candidateUsers) {
    const applicationCount = Math.floor(Math.random() * 5) + 1;
    const jobsToApply = getRandomElements(createdJobs, 1, Math.min(applicationCount, createdJobs.length));
    
    for (const job of jobsToApply) {
      if (job.user_id !== candidate.id) {
        applications.push({
          job_post_id: job.id,
          user_id: candidate.id,
        });
      }
    }
  }

  if (applications.length > 0) {
    await prisma.job_applications.createMany({
      data: applications,
      skipDuplicates: true,
    });
  }

  console.log(`Created ${applications.length} job applications`);

  // Final statistics
  console.log('\n=== SEEDING COMPLETE ===');
  console.log(`Countries: ${countries.length}`);
  console.log(`Cities: ${cities.length}`);
  console.log(`Users: ${createdUsers.length} (${recruiterCount} recruiters, ${candidateUsers.length} candidates)`);
  console.log(`Job Posts: ${createdJobs.length}`);
  console.log(`Job Applications: ${applications.length}`);
  console.log(`Job Categories: ${jobCategories.length}`);
  console.log(`Currencies: ${currencies.length}`);
  console.log('\nFilm industry database seeding completed successfully!');
}

function getSalaryMultiplier(countryName) {
  const multipliers = {
    'United States': 1.0,
    'Canada': 0.8,
    'United Kingdom': 0.9,
    'France': 0.7,
    'Germany': 0.8,
    'Italy': 0.6,
    'Spain': 0.5,
    'India': 0.2
  };
  return multipliers[countryName] || 0.7;
}

function getCurrencyForCountry(currencies, countryName) {
  const currencyMap = {
    'United States': 'USD',
    'Canada': 'CAD',
    'United Kingdom': 'GBP',
    'France': 'EUR',
    'Germany': 'EUR',
    'Italy': 'EUR',
    'Spain': 'EUR',
    'India': 'INR'
  };
  
  const currencyCode = currencyMap[countryName] || 'USD';
  const currency = currencies.find(c => c.name === currencyCode);
  return currency ? currency.id : currencies[0].id;
}

main()
  .catch(async (e) => {
    console.error('Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });