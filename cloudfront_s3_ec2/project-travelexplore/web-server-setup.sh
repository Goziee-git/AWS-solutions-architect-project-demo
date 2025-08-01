#!/bin/bash

# Update system packages
yum update -y

# Install Apache web server
yum install -y httpd

# Install PHP for dynamic content
yum install -y php php-mysql

# Install AWS CLI
yum install -y aws-cli

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Set permissions
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

# Create website directory structure
mkdir -p /var/www/html/css
mkdir -p /var/www/html/js
mkdir -p /var/www/html/images
mkdir -p /var/www/html/admin

# Create index.html
cat > /var/www/html/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TravelExplore - Discover Your Next Adventure</title>
    <link rel="stylesheet" href="css/styles.css">
    <script src="js/script.js" defer></script>
</head>
<body>
    <header>
        <div class="container">
            <h1>Travel<span>Explore</span></h1>
            <nav>
                <ul>
                    <li><a href="#" class="active">Home</a></li>
                    <li><a href="#destinations">Destinations</a></li>
                    <li><a href="#guides">Travel Guides</a></li>
                    <li><a href="#about">About Us</a></li>
                    <li><a href="#contact">Contact</a></li>
                </ul>
            </nav>
        </div>
    </header>
    
    <section class="hero">
        <div class="container">
            <h2>Discover Your Next Adventure</h2>
            <p>Explore breathtaking destinations around the world with our expert travel guides</p>
            <a href="#destinations" class="btn">Explore Destinations</a>
        </div>
    </section>
    
    <section id="destinations" class="destinations">
        <div class="container">
            <h2>Popular Destinations</h2>
            <div class="destination-grid">
                <!-- Destinations will be loaded dynamically -->
                <div id="destinations-container">Loading destinations...</div>
            </div>
        </div>
    </section>
    
    <section id="guides" class="guides">
        <div class="container">
            <h2>Travel Guides</h2>
            <div class="guides-grid">
                <!-- Guides will be loaded dynamically -->
                <div id="guides-container">Loading guides...</div>
            </div>
        </div>
    </section>
    
    <footer>
        <div class="container">
            <div class="footer-content">
                <div class="footer-logo">
                    <h2>Travel<span>Explore</span></h2>
                    <p>Your journey begins with us</p>
                </div>
                <div class="footer-links">
                    <h3>Quick Links</h3>
                    <ul>
                        <li><a href="#">Home</a></li>
                        <li><a href="#destinations">Destinations</a></li>
                        <li><a href="#guides">Travel Guides</a></li>
                        <li><a href="#about">About Us</a></li>
                        <li><a href="#contact">Contact</a></li>
                    </ul>
                </div>
                <div class="footer-info">
                    <h3>Server Information</h3>
                    <p>Region: <span id="region">Loading...</span></p>
                    <p>Instance ID: <span id="instance-id">Loading...</span></p>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; 2025 TravelExplore. All Rights Reserved.</p>
            </div>
        </div>
    </footer>
</body>
</html>
EOL

# Create CSS file
cat > /var/www/html/css/styles.css << 'EOL'
/* Base Styles */
:root {
    --primary-color: #3498db;
    --secondary-color: #2c3e50;
    --accent-color: #e74c3c;
    --light-color: #ecf0f1;
    --dark-color: #2c3e50;
    --text-color: #333;
    --text-light: #f4f4f4;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: var(--text-color);
    background-color: #f9f9f9;
}

.container {
    width: 90%;
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 15px;
}

a {
    text-decoration: none;
    color: var(--primary-color);
    transition: all 0.3s ease;
}

ul {
    list-style: none;
}

/* Header */
header {
    background-color: white;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    position: fixed;
    width: 100%;
    top: 0;
    z-index: 1000;
}

header .container {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 15px;
}

header h1 {
    font-size: 1.8rem;
    margin-bottom: 0;
}

header h1 span {
    color: var(--primary-color);
}

nav ul {
    display: flex;
}

nav ul li {
    margin-left: 25px;
}

nav ul li a {
    color: var(--dark-color);
    font-weight: 500;
    padding: 5px 0;
    position: relative;
}

nav ul li a:hover,
nav ul li a.active {
    color: var(--primary-color);
}

/* Hero Section */
.hero {
    background-image: linear-gradient(rgba(0, 0, 0, 0.6), rgba(0, 0, 0, 0.6)), url('https://travelexplore-assets-primary.s3.amazonaws.com/images/hero-bg.jpg');
    background-size: cover;
    background-position: center;
    height: 100vh;
    display: flex;
    align-items: center;
    text-align: center;
    color: white;
    margin-top: 60px;
}

.hero h2 {
    font-size: 3.5rem;
    margin-bottom: 20px;
}

.hero p {
    font-size: 1.2rem;
    margin-bottom: 30px;
    max-width: 700px;
    margin-left: auto;
    margin-right: auto;
}

.btn {
    display: inline-block;
    background-color: var(--primary-color);
    color: white;
    padding: 12px 25px;
    border-radius: 5px;
    text-transform: uppercase;
    font-weight: 600;
    letter-spacing: 1px;
    transition: all 0.3s ease;
}

.btn:hover {
    background-color: #2980b9;
    transform: translateY(-3px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

/* Sections */
section {
    padding: 80px 0;
}

section h2 {
    text-align: center;
    font-size: 2.5rem;
    margin-bottom: 50px;
    position: relative;
}

section h2::after {
    content: '';
    position: absolute;
    bottom: -15px;
    left: 50%;
    transform: translateX(-50%);
    width: 80px;
    height: 3px;
    background-color: var(--primary-color);
}

/* Destinations */
.destination-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 30px;
}

.destination-card {
    border-radius: 10px;
    overflow: hidden;
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
    transition: all 0.3s ease;
}

.destination-card:hover {
    transform: translateY(-10px);
}

.destination-card img {
    height: 200px;
    object-fit: cover;
    width: 100%;
}

.destination-info {
    padding: 20px;
}

.destination-info h3 {
    margin-bottom: 10px;
}

.destination-info p {
    margin-bottom: 15px;
    color: #666;
}

/* Guides */
.guides {
    background-color: #f9f9f9;
}

.guides-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 30px;
}

.guide-card {
    background-color: white;
    padding: 30px;
    border-radius: 10px;
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
    text-align: center;
    transition: all 0.3s ease;
}

.guide-card:hover {
    transform: translateY(-10px);
}

.guide-icon {
    font-size: 2.5rem;
    color: var(--primary-color);
    margin-bottom: 20px;
}

.guide-card h3 {
    margin-bottom: 15px;
}

.guide-card p {
    margin-bottom: 20px;
    color: #666;
}

/* Footer */
footer {
    background-color: var(--secondary-color);
    color: var(--text-light);
    padding: 60px 0 20px;
}

.footer-content {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 30px;
    margin-bottom: 40px;
}

.footer-logo h2 {
    font-size: 1.8rem;
}

.footer-logo span {
    color: var(--primary-color);
}

.footer-logo p {
    margin-top: 10px;
}

.footer-links h3,
.footer-info h3 {
    font-size: 1.2rem;
    margin-bottom: 20px;
    position: relative;
    padding-bottom: 10px;
}

.footer-links h3::after,
.footer-info h3::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 0;
    width: 50px;
    height: 2px;
    background-color: var(--primary-color);
}

.footer-links ul li {
    margin-bottom: 10px;
}

.footer-links ul li a {
    color: var(--text-light);
    opacity: 0.8;
}

.footer-links ul li a:hover {
    opacity: 1;
    color: var(--primary-color);
}

.footer-info p {
    margin-bottom: 10px;
}

.footer-info span {
    color: var(--primary-color);
    font-weight: bold;
}

.footer-bottom {
    text-align: center;
    padding-top: 20px;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
}

/* Responsive Design */
@media (max-width: 768px) {
    header .container {
        flex-direction: column;
    }
    
    nav ul {
        margin-top: 20px;
    }
    
    nav ul li {
        margin: 0 10px;
    }
    
    .hero h2 {
        font-size: 2.5rem;
    }
}

@media (max-width: 576px) {
    nav ul {
        flex-wrap: wrap;
        justify-content: center;
    }
    
    nav ul li {
        margin: 5px 10px;
    }
    
    .hero h2 {
        font-size: 2rem;
    }
    
    .hero p {
        font-size: 1rem;
    }
    
    section h2 {
        font-size: 2rem;
    }
}
EOL

# Create JavaScript file
cat > /var/www/html/js/script.js << 'EOL'
// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    // Load server information
    loadServerInfo();
    
    // Load destinations
    loadDestinations();
    
    // Load guides
    loadGuides();
    
    // Smooth scrolling for navigation links
    const navLinks = document.querySelectorAll('nav a, .footer-links a, .hero a');
    
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            // Only apply to links that start with #
            if(this.getAttribute('href').startsWith('#')) {
                e.preventDefault();
                
                const targetId = this.getAttribute('href');
                
                // Skip if it's just #
                if(targetId === '#') return;
                
                const targetElement = document.querySelector(targetId);
                
                if(targetElement) {
                    // Get the header height for offset
                    const headerHeight = document.querySelector('header').offsetHeight;
                    
                    // Calculate the position to scroll to
                    const targetPosition = targetElement.offsetTop - headerHeight;
                    
                    // Smooth scroll to the target
                    window.scrollTo({
                        top: targetPosition,
                        behavior: 'smooth'
                    });
                    
                    // Update active link
                    navLinks.forEach(link => link.classList.remove('active'));
                    this.classList.add('active');
                }
            }
        });
    });
});

// Load server information
async function loadServerInfo() {
    try {
        // Get instance metadata
        const instanceId = await fetch('http://169.254.169.254/latest/meta-data/instance-id').then(r => r.text());
        const availabilityZone = await fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone').then(r => r.text());
        
        // Extract region from AZ
        const region = availabilityZone.slice(0, -1);
        
        // Update the DOM
        document.getElementById('region').textContent = region;
        document.getElementById('instance-id').textContent = instanceId;
    } catch (error) {
        console.error('Error fetching instance metadata:', error);
        document.getElementById('region').textContent = 'Unknown';
        document.getElementById('instance-id').textContent = 'Unknown';
    }
}

// Load destinations
function loadDestinations() {
    // In a real application, this would fetch data from an API
    // For this demo, we'll use hardcoded data
    const destinations = [
        {
            name: 'Paris, France',
            description: 'The city of lights and romance',
            image: 'https://travelexplore-assets-primary.s3.amazonaws.com/images/paris.jpg'
        },
        {
            name: 'Tokyo, Japan',
            description: 'Where tradition meets innovation',
            image: 'https://travelexplore-assets-primary.s3.amazonaws.com/images/tokyo.jpg'
        },
        {
            name: 'New York, USA',
            description: 'The city that never sleeps',
            image: 'https://travelexplore-assets-primary.s3.amazonaws.com/images/new-york.jpg'
        },
        {
            name: 'Sydney, Australia',
            description: 'Harbor city with iconic landmarks',
            image: 'https://travelexplore-assets-primary.s3.amazonaws.com/images/sydney.jpg'
        }
    ];
    
    const container = document.getElementById('destinations-container');
    
    if (container) {
        container.innerHTML = destinations.map(dest => `
            <div class="destination-card">
                <img src="${dest.image}" alt="${dest.name}">
                <div class="destination-info">
                    <h3>${dest.name}</h3>
                    <p>${dest.description}</p>
                    <a href="#" class="btn">View Guide</a>
                </div>
            </div>
        `).join('');
    }
}

// Load guides
function loadGuides() {
    // In a real application, this would fetch data from an API
    // For this demo, we'll use hardcoded data
    const guides = [
        {
            title: 'City Guides',
            description: 'Comprehensive guides to the world\'s most exciting cities',
            icon: '🏙️'
        },
        {
            title: 'Adventure Travel',
            description: 'Guides for thrill-seekers and outdoor enthusiasts',
            icon: '🏔️'
        },
        {
            title: 'Food & Culture',
            description: 'Explore local cuisines and cultural experiences',
            icon: '🍲'
        }
    ];
    
    const container = document.getElementById('guides-container');
    
    if (container) {
        container.innerHTML = guides.map(guide => `
            <div class="guide-card">
                <div class="guide-icon">${guide.icon}</div>
                <h3>${guide.title}</h3>
                <p>${guide.description}</p>
                <a href="#" class="btn">Browse Guides</a>
            </div>
        `).join('');
    }
}
EOL

# Create a simple PHP file to demonstrate dynamic content
cat > /var/www/html/server-info.php << 'EOL'
<?php
// Get server information
$serverInfo = [
    'server_software' => $_SERVER['SERVER_SOFTWARE'],
    'php_version' => phpversion(),
    'server_time' => date('Y-m-d H:i:s'),
    'server_ip' => $_SERVER['SERVER_ADDR']
];

// Return as JSON
header('Content-Type: application/json');
echo json_encode($serverInfo);
EOL

# Create a placeholder for admin area
cat > /var/www/html/admin/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TravelExplore Admin</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #3498db;
        }
        .login-form {
            margin-top: 20px;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
        }
        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        button {
            background-color: #3498db;
            color: white;
            border: none;
            padding: 10px 15px;
            border-radius: 4px;
            cursor: pointer;
        }
        button:hover {
            background-color: #2980b9;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>TravelExplore Admin Portal</h1>
        <p>This is a placeholder for the admin interface. In a real application, this would be a secure, authenticated area for content management.</p>
        
        <div class="login-form">
            <h2>Login</h2>
            <form>
                <div class="form-group">
                    <label for="username">Username:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                <div class="form-group">
                    <label for="password">Password:</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <button type="submit">Login</button>
            </form>
        </div>
    </div>
    
    <script>
        // Prevent form submission (for demo purposes)
        document.querySelector('form').addEventListener('submit', function(e) {
            e.preventDefault();
            alert('This is a demo. Login functionality is not implemented.');
        });
    </script>
</body>
</html>
EOL

# Set proper permissions
chmod -R 755 /var/www/html

# Create a message to indicate successful setup
echo "TravelExplore web server setup complete!" > /var/www/html/setup-complete.txt
