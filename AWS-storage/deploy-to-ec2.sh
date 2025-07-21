#!/bin/bash

# EC2 Static Website Deployment Script
# This script automates the deployment of a static website to an EC2 instance

# Configuration
EC2_HOST="ec2-user@your-ec2-instance-public-dns"  # Replace with your EC2 instance's public DNS
KEY_PATH="~/.ssh/your-key.pem"                    # Replace with the path to your key file
WEBSITE_DIR="./sample-website"                    # Directory containing your website files
REMOTE_DIR="/var/www/html"                        # Remote directory on EC2 instance

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== EC2 Static Website Deployment ===${NC}"

# Check if SSH key exists
if [ ! -f "$KEY_PATH" ]; then
    echo -e "${RED}Error: SSH key file '$KEY_PATH' not found.${NC}"
    exit 1
fi

# Check if the website directory exists
if [ ! -d "$WEBSITE_DIR" ]; then
    echo -e "${RED}Error: Website directory '$WEBSITE_DIR' not found.${NC}"
    exit 1
fi

# Check SSH connection
echo -e "${YELLOW}Testing SSH connection to EC2 instance...${NC}"
if ! ssh -i "$KEY_PATH" -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$EC2_HOST" "echo 'Connection successful'" &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to EC2 instance. Please check your EC2_HOST and KEY_PATH.${NC}"
    exit 1
fi
echo -e "${GREEN}SSH connection successful.${NC}"

# Install and configure Apache if not already installed
echo -e "${YELLOW}Checking and installing Apache web server...${NC}"
ssh -i "$KEY_PATH" "$EC2_HOST" "
    if ! command -v httpd &> /dev/null; then
        echo 'Installing Apache...'
        sudo yum update -y
        sudo yum install -y httpd
        sudo systemctl start httpd
        sudo systemctl enable httpd
        echo 'Apache installed successfully.'
    else
        echo 'Apache is already installed.'
    fi

    # Set permissions
    sudo usermod -a -G apache ec2-user
    sudo chown -R ec2-user:apache /var/www
    sudo chmod 2775 /var/www
    find /var/www -type d -exec sudo chmod 2775 {} \;
    find /var/www -type f -exec sudo chmod 0664 {} \;
"

# Clear the remote directory
echo -e "${YELLOW}Clearing remote directory...${NC}"
ssh -i "$KEY_PATH" "$EC2_HOST" "sudo rm -rf $REMOTE_DIR/*"

# Upload website files
echo -e "${YELLOW}Uploading website files...${NC}"
scp -i "$KEY_PATH" -r "$WEBSITE_DIR"/* "$EC2_HOST:$REMOTE_DIR/"

# Set proper permissions
echo -e "${YELLOW}Setting proper permissions...${NC}"
ssh -i "$KEY_PATH" "$EC2_HOST" "
    sudo find $REMOTE_DIR -type d -exec chmod 2775 {} \;
    sudo find $REMOTE_DIR -type f -exec chmod 0664 {} \;
    sudo chown -R ec2-user:apache $REMOTE_DIR
"

# Restart Apache
echo -e "${YELLOW}Restarting Apache...${NC}"
ssh -i "$KEY_PATH" "$EC2_HOST" "sudo systemctl restart httpd"

# Get public IP address
PUBLIC_IP=$(ssh -i "$KEY_PATH" "$EC2_HOST" "curl -s http://169.254.169.254/latest/meta-data/public-ipv4")

# Display website URL
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}Website URL: http://$PUBLIC_IP${NC}"
echo -e "${YELLOW}Note: It may take a few moments for the changes to take effect.${NC}"

# Additional information
echo -e "\n${YELLOW}=== Next Steps ===${NC}"
echo -e "1. To use a custom domain, configure Route 53 and point it to your EC2 instance."
echo -e "2. For HTTPS support, install and configure SSL certificates using Let's Encrypt."
echo -e "3. For better security, consider setting up a more restrictive security group."
echo -e "4. For high availability, consider setting up an Auto Scaling Group with a Load Balancer."
