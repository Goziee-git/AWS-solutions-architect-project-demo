#!/bin/bash

# Minimal user data script for EC2 instance setup
yum update -y
yum install -y httpd php
systemctl start httpd
systemctl enable httpd

# Create a simple web page
cat > /var/www/html/index.html <<EOF
<html>
<head><title>${project_name} - Terraform Deployment</title></head>
<body>
<h1>${project_name}</h1>
<p>Environment: ${environment}</p>
<p>VPC CIDR: ${vpc_cidr}</p>
<p>Deployed with Terraform</p>
</body>
</html>
EOF

# Create a simple health check endpoint
echo OK > /var/www/html/health

# Set permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Restart Apache
systemctl restart httpd
