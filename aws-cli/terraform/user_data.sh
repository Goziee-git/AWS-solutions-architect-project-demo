#!/bin/bash

# User data script for EC2 instance setup
# This script runs when the instance first boots

# Update system packages
yum update -y

# Install Apache web server
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Install additional useful packages
yum install -y htop curl wget unzip

# Create a comprehensive web page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${project_name} - Terraform Deployment</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #232F3E 0%, #FF9900 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        
        .content {
            padding: 40px;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 30px;
            margin-bottom: 40px;
        }
        
        .info-card {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 10px;
            border-left: 5px solid #FF9900;
        }
        
        .info-card h3 {
            color: #232F3E;
            margin-bottom: 15px;
            font-size: 1.3em;
        }
        
        .info-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding: 8px 0;
            border-bottom: 1px solid #e9ecef;
        }
        
        .info-item:last-child {
            border-bottom: none;
        }
        
        .label {
            font-weight: 600;
            color: #495057;
        }
        
        .value {
            color: #FF9900;
            font-weight: 500;
            font-family: 'Courier New', monospace;
        }
        
        .architecture-list {
            background: #e8f5e8;
            padding: 25px;
            border-radius: 10px;
            margin: 30px 0;
        }
        
        .architecture-list h3 {
            color: #155724;
            margin-bottom: 20px;
            font-size: 1.3em;
        }
        
        .architecture-list ul {
            list-style: none;
        }
        
        .architecture-list li {
            padding: 8px 0;
            position: relative;
            padding-left: 30px;
        }
        
        .architecture-list li:before {
            content: "✅";
            position: absolute;
            left: 0;
        }
        
        .terraform-info {
            background: #e3f2fd;
            padding: 25px;
            border-radius: 10px;
            margin: 30px 0;
        }
        
        .terraform-info h3 {
            color: #0d47a1;
            margin-bottom: 15px;
        }
        
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #6c757d;
            border-top: 1px solid #e9ecef;
        }
        
        .status-badge {
            display: inline-block;
            background: #28a745;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            margin-left: 10px;
        }
        
        @media (max-width: 768px) {
            .info-grid {
                grid-template-columns: 1fr;
            }
            
            .header h1 {
                font-size: 2em;
            }
            
            .content {
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 ${project_name}</h1>
            <p>Terraform Infrastructure Deployment <span class="status-badge">ACTIVE</span></p>
        </div>
        
        <div class="content">
            <div class="info-grid">
                <div class="info-card">
                    <h3>📊 Instance Information</h3>
                    <div class="info-item">
                        <span class="label">Instance ID:</span>
                        <span class="value" id="instance-id">Loading...</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Instance Type:</span>
                        <span class="value" id="instance-type">Loading...</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Availability Zone:</span>
                        <span class="value" id="availability-zone">Loading...</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Public IP:</span>
                        <span class="value" id="public-ip">Loading...</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Private IP:</span>
                        <span class="value" id="private-ip">Loading...</span>
                    </div>
                </div>
                
                <div class="info-card">
                    <h3>🌐 Network Information</h3>
                    <div class="info-item">
                        <span class="label">VPC ID:</span>
                        <span class="value" id="vpc-id">Loading...</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Subnet ID:</span>
                        <span class="value" id="subnet-id">Loading...</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Security Groups:</span>
                        <span class="value" id="security-groups">Loading...</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Region:</span>
                        <span class="value" id="region">Loading...</span>
                    </div>
                </div>
            </div>
            
            <div class="architecture-list">
                <h3>🏗️ Infrastructure Components</h3>
                <ul>
                    <li>Custom VPC with DNS support (${vpc_cidr})</li>
                    <li>Public Subnet with auto-assign public IP</li>
                    <li>Private Subnet for backend resources</li>
                    <li>Internet Gateway for connectivity</li>
                    <li>Route Table with internet routing</li>
                    <li>Security Group with HTTP/HTTPS/SSH access</li>
                    <li>EC2 Instance with Apache web server</li>
                    <li>Encrypted EBS root volume</li>
                </ul>
            </div>
            
            <div class="terraform-info">
                <h3>🔧 Terraform Deployment Info</h3>
                <p><strong>Environment:</strong> ${environment}</p>
                <p><strong>Managed By:</strong> Terraform</p>
                <p><strong>Deployment Date:</strong> <span id="deployment-date"></span></p>
                <p><strong>Server Uptime:</strong> <span id="uptime">Loading...</span></p>
            </div>
        </div>
        
        <div class="footer">
            <p>This infrastructure was deployed using <strong>Terraform</strong> on <strong>Amazon Web Services</strong></p>
            <p>Apache HTTP Server running on Amazon Linux 2 • Last updated: <span id="last-updated"></span></p>
        </div>
    </div>

    <script>
        // Fetch instance metadata
        async function fetchMetadata() {
            const baseUrl = 'http://169.254.169.254/latest/meta-data/';
            
            try {
                const [instanceId, instanceType, az, publicIp, privateIp, vpcId, subnetId, securityGroups, region] = await Promise.all([
                    fetch(baseUrl + 'instance-id').then(r => r.text()),
                    fetch(baseUrl + 'instance-type').then(r => r.text()),
                    fetch(baseUrl + 'placement/availability-zone').then(r => r.text()),
                    fetch(baseUrl + 'public-ipv4').then(r => r.text()).catch(() => 'N/A'),
                    fetch(baseUrl + 'local-ipv4').then(r => r.text()),
                    fetch(baseUrl + 'network/interfaces/macs/').then(r => r.text()).then(mac => 
                        fetch(baseUrl + `network/interfaces/macs/$${mac.trim()}/vpc-id`).then(r => r.text())
                    ),
                    fetch(baseUrl + 'network/interfaces/macs/').then(r => r.text()).then(mac => 
                        fetch(baseUrl + `network/interfaces/macs/$${mac.trim()}/subnet-id`).then(r => r.text())
                    ),
                    fetch(baseUrl + 'security-groups').then(r => r.text()),
                    fetch(baseUrl + 'placement/region').then(r => r.text())
                ]);
                
                document.getElementById('instance-id').textContent = instanceId;
                document.getElementById('instance-type').textContent = instanceType;
                document.getElementById('availability-zone').textContent = az;
                document.getElementById('public-ip').textContent = publicIp;
                document.getElementById('private-ip').textContent = privateIp;
                document.getElementById('vpc-id').textContent = vpcId;
                document.getElementById('subnet-id').textContent = subnetId;
                document.getElementById('security-groups').textContent = securityGroups;
                document.getElementById('region').textContent = region;
                
            } catch (error) {
                console.error('Error fetching metadata:', error);
                document.querySelectorAll('.value').forEach(el => {
                    if (el.textContent === 'Loading...') {
                        el.textContent = 'Error loading';
                    }
                });
            }
        }
        
        // Set timestamps
        document.getElementById('deployment-date').textContent = new Date().toLocaleDateString();
        document.getElementById('last-updated').textContent = new Date().toLocaleString();
        
        // Fetch uptime
        fetch('/proc/uptime')
            .then(response => response.text())
            .then(data => {
                const uptime = parseFloat(data.split(' ')[0]);
                const days = Math.floor(uptime / 86400);
                const hours = Math.floor((uptime % 86400) / 3600);
                const minutes = Math.floor((uptime % 3600) / 60);
                document.getElementById('uptime').textContent = `$${days}d $${hours}h $${minutes}m`;
            })
            .catch(() => {
                document.getElementById('uptime').textContent = 'N/A';
            });
        
        // Load metadata when page loads
        fetchMetadata();
        
        // Refresh metadata every 30 seconds
        setInterval(fetchMetadata, 30000);
    </script>
</body>
</html>
EOF

# Create a simple API endpoint for system information
cat > /var/www/html/api.php << 'EOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$data = array(
    'timestamp' => date('c'),
    'server_info' => array(
        'software' => 'Apache/' . apache_get_version(),
        'php_version' => phpversion(),
        'system' => php_uname(),
        'load_average' => sys_getloadavg()
    ),
    'environment' => '${environment}',
    'project' => '${project_name}',
    'managed_by' => 'Terraform'
);

echo json_encode($data, JSON_PRETTY_PRINT);
?>
EOF

# Install PHP for the API endpoint
yum install -y php

# Create system info script
cat > /usr/local/bin/system-info.sh << 'EOF'
#!/bin/bash
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"
echo "Disk Usage:"
df -h /
echo "Memory Usage:"
free -h
echo "Network Interfaces:"
ip addr show | grep -E "inet|mtu"
echo "Active Services:"
systemctl list-units --type=service --state=active | grep -E "(httpd|sshd)"
EOF

chmod +x /usr/local/bin/system-info.sh

# Create a simple health check endpoint
cat > /var/www/html/health << 'EOF'
OK
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 644 /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;

# Configure Apache
cat > /etc/httpd/conf.d/custom.conf << 'EOF'
# Custom Apache configuration
ServerTokens Prod
ServerSignature Off

# Security headers
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"

# Enable compression
LoadModule deflate_module modules/mod_deflate.so
<Location />
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI \
        \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI \
        \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
</Location>
EOF

# Restart Apache to apply configuration
systemctl restart httpd

# Create log rotation for custom logs
cat > /etc/logrotate.d/custom-app << 'EOF'
/var/log/custom-app.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 apache apache
}
EOF

# Log deployment completion
echo "$(date): Terraform deployment completed successfully" >> /var/log/custom-app.log

# Signal completion (for CloudFormation compatibility)
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region} 2>/dev/null || echo "Terraform deployment completed"
EOF
