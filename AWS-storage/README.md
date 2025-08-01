# Static Website Hosting on AWS

This guide provides detailed instructions for hosting static websites on AWS using two different approaches:
1. Amazon S3 (Simple Storage Service)
2. Amazon EC2 (Elastic Compute Cloud)

## Table of Contents
- [Overview](#overview)
- [S3 Static Website Hosting](#s3-static-website-hosting)
- [EC2 Static Website Hosting](#ec2-static-website-hosting)
- [Production-Level Configurations](#production-level-configurations)
- [Sample Scenarios](#sample-scenarios)
- [Project: Multi-Region Content Delivery Solution](#project-multi-region-content-delivery-solution)

## Overview

Static websites consist of HTML, CSS, JavaScript, images, and other client-side files that don't require server-side processing. AWS offers multiple ways to host these websites, each with its own advantages:

### S3 Advantages
- Serverless (no server management)
- Highly available and durable
- Cost-effective for static content
- Scales automatically
- Can be integrated with CloudFront for global distribution

### EC2 Advantages
- Full control over the web server
- Can run dynamic content alongside static content
- Customizable server configurations
- Suitable for complex applications
- Can be part of a larger architecture

## S3 Static Website Hosting

### Step 1: Create an S3 Bucket
1. Sign in to the AWS Management Console
2. Navigate to the S3 service
3. Click "Create bucket"
4. Enter a globally unique bucket name
5. Select the AWS Region closest to your users
6. Unblock all public access (for website hosting)
7. Enable bucket versioning (recommended for production)
8. Click "Create bucket"

### Step 2: Configure Static Website Hosting
1. Select your bucket from the S3 console
2. Go to the "Properties" tab
3. Scroll down to "Static website hosting"
4. Click "Edit"
5. Select "Enable" 
6. Set "Index document" to `index.html`
7. Set "Error document" to `error.html`
8. Click "Save changes"
9. Note the "Bucket website endpoint" URL

### Step 3: Set Bucket Policy for Public Access
1. Go to the "Permissions" tab
2. Under "Bucket policy", click "Edit"
3. Add the following policy (replace `your-bucket-name` with your actual bucket name):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        }
    ]
}
```
4. Click "Save changes"

### Step 4: Upload Website Files
1. Go to the "Objects" tab
2. Click "Upload"
3. Add your website files (HTML, CSS, JS, images, etc.)

**NOTE** : when uploading files or folders to the S3 bucket, your code files like ```style.css/``` and ```scipt.js``` can be in a nested format, but the ```index.html``` and the ```error.html``` must be uploaded as files in the root of your bucket and not in a nested folder. 
to confirm check the object ARN and ensure that it conforms to this S3 standard.

4. Click "Upload"

### Step 5: Access Your Website
- Visit the S3 website endpoint URL (found in the "Properties" tab)
- Format: `http://your-bucket-name.s3-website-region.amazonaws.com`

## EC2 Static Website Hosting

### Step 1: Launch an EC2 Instance
1. Navigate to the EC2 console
2. Click "Launch instance"
3. Choose an Amazon Linux 2 AMI
4. Select an instance type (t2.micro is eligible for free tier)
5. Configure instance details (use default settings for basic setup)
6. Add storage (default is sufficient for a static website)
7. Add tags (Name: StaticWebServer)
8. Configure security group:
   - Allow SSH (port 22) from your IP
   - Allow HTTP (port 80) from anywhere
   - Allow HTTPS (port 443) from anywhere
9. Review and launch
10. Create or select a key pair for SSH access
11. Launch instance

### Step 2: Connect to Your Instance
```bash
ssh -i /path/to/your-key.pem ec2-user@your-instance-public-ip
```
for example, if your RSA public key is ```prospa.pem``` is in your tilde(~) directory, you do ```ssd -i prospa.pem ec2-user@your-instance-public-ip```

### Step 3: Install Web Server (Apache)
```bash
# The command below uses the yum package manager to update the ec2 instance that you have created a secure connection to via ssh.
sudo yum update -y

# The command below is used to install the apache webserver using the httpd installation candidate. The webserver is a software that is used together with a server like an ec2 instance to serve static and dynamic files like website files to users over a server.
sudo yum install -y httpd

# we use systemctl as a command line utility to start the apache webserver with this command below
sudo systemctl start httpd

# here again we are using the systemctl utility to enable the webserver, this will allow the webserver to run, when we both the intance.
sudo systemctl enable httpd

# the command below is used to add the host with hostname (ec2-user) to the apache group
sudo usermod -a -G apache ec2-user
# after doing the command above, to verify this, do this command from your / directory 
```cat/etc/groups``` 

#the command below changes the ownership for the files in /var/www/ from the ec2-user to the apache 
sudo chown -R ec2-user:apache /var/www

sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;
```

### Step 4: Upload Website Files 
(if you have the files on your local machine) if not then clone this repository

Option 1: Using SCP
```bash
scp -i /path/to/your-key.pem -r /path/to/local/website/* ec2-user@your-instance-public-dns:/var/www/html/

#for example if your RSA.pem and static-file are in the linux working directory(~), you should take note of your public-ip address and do the command like this
scp -i ~/rsa.pem -r ~/static-website-files/* ec2-user@ip-addr:/var/www/html
```

Option 2: Using Git
you should only consider this option if you want to use Git within the ec2 server in the cloud. For this project we didnt use this step because of vCPU for free tier was 2, and it is not advisable to bloat instance storage. here are the High level steps
```bash
# Install Git 
sudo yum install -y git

# Navigate to web directory
cd /var/www/html

# Clone your website repository
sudo git clone https://github.com/yourusername/your-website-repo.git .
```

Option 3: Create files directly on the server
```bash
# Create index.html
sudo nano /var/www/html/index.html
# Paste your HTML content, save and exit (Ctrl+X, Y, Enter)
```

### Step 5: Access Your Website
- Visit your EC2 instance's public DNS or IP address in a web browser
- Format: `http://your-instance-public-dns` or `http://your-instance-public-ip`

## Production-Level Configurations

### S3 Production Configuration

1. **Custom Domain with Route 53**
   - Register a domain in Route 53 or use an existing domain
   - Create a hosted zone for your domain
   - Create an alias record pointing to your S3 website endpoint

2. **CloudFront Distribution**
   - Create a CloudFront distribution with your S3 bucket as the origin
   - Enable HTTPS with an ACM certificate
   - Configure caching behaviors
   - Set up geo-restrictions if needed
   - Enable logging

3. **S3 Bucket Configuration**
   - Enable versioning
   - Configure lifecycle rules
   - Set up server access logging
   - Implement CORS if needed
   - Enable default encryption

4. **Security Best Practices**
   - Use bucket policies to restrict access
   - Implement AWS WAF with CloudFront
   - Set up CloudTrail for API logging
   - Use S3 Object Lock for critical files

### EC2 Production Configuration

1. **High Availability Setup**
   - Use Auto Scaling Group with multiple instances
   - Deploy across multiple Availability Zones
   - Set up an Application Load Balancer

2. **HTTPS Configuration**
   - Obtain an SSL certificate (using AWS Certificate Manager)
   - Configure Apache/Nginx for HTTPS
   - Redirect HTTP to HTTPS
   - Implement proper SSL security headers

3. **Performance Optimization**
   - Configure caching headers
   - Enable gzip compression
   - Use CloudFront as a CDN
   - Optimize instance type based on traffic

4. **Security Hardening**
   - Use security groups and NACLs
   - Implement AWS WAF
   - Regular security patches
   - Use IMDSv2 for instance metadata
   - Implement least privilege IAM roles

5. **Monitoring and Logging**
   - Set up CloudWatch alarms
   - Configure detailed monitoring
   - Enable access logs
   - Set up log rotation
   - Implement health checks

## Sample Scenarios

### Scenario 1: Corporate Marketing Website
**Setup**: S3 + CloudFront
- High-traffic marketing website with global audience
- Frequent content updates by marketing team
- Need for fast global content delivery
- Cost optimization for static content

### Scenario 2: E-commerce Product Catalog
**Setup**: EC2 + CloudFront
- Dynamic product search functionality
- Static product images and descriptions
- Need for server-side processing for search
- High availability requirements during sales events

### Scenario 3: Software Documentation Portal
**Setup**: S3 for documentation + EC2 for API reference
- Versioned documentation in S3
- Interactive API explorer on EC2
- Global developer audience
- Frequent documentation updates

### Scenario 4: Event Microsite
**Setup**: S3 only
- Temporary website for specific event
- Simple design with registration form
- Cost-effective solution for short-term use
- Easy deployment and teardown

### Scenario 5: Internal Knowledge Base
**Setup**: EC2 behind VPC
- Company internal documentation
- Access restricted to corporate network
- Integration with internal authentication
- Mix of static content and search functionality

## Project: Multi-Region Content Delivery Solution

### Business Scenario
TravelExplore, a global travel agency, needs to deliver their content-rich travel guides to users worldwide with minimal latency. The website includes:
- High-resolution destination images
- Interactive maps
- Travel guides in PDF format
- User reviews and ratings
- Booking information

### Requirements
1. Fast content delivery to users in North America, Europe, and Asia
2. Cost-effective solution for storing and serving large media files
3. Ability to update content frequently
4. High availability and disaster recovery capabilities
5. Secure access to administrative functions

### Solution Architecture
Implement a hybrid approach using both S3 and EC2:

1. **S3 for Static Content**
   - Store images, PDFs, and other static assets
   - Configure as a static website for direct access
   - Implement multi-region replication for disaster recovery

2. **EC2 for Dynamic Features**
   - Host the main website application
   - Implement user authentication
   - Provide admin interface for content management
   - Connect to backend services and databases

3. **CloudFront for Global Distribution**
   - Distribute content from both S3 and EC2 origins
   - Configure geo-based routing
   - Implement caching strategies

4. **Route 53 for DNS Management**
   - Set up health checks and failover routing
   - Implement latency-based routing

### Implementation Tasks
1. Set up S3 buckets in multiple regions
2. Configure EC2 instances with Auto Scaling
3. Implement CloudFront distribution
4. Set up Route 53 with appropriate routing policies
5. Configure monitoring and alerting
6. Implement backup and disaster recovery procedures

This project demonstrates how to effectively combine S3 and EC2 to deliver a comprehensive solution that leverages the strengths of each service.
