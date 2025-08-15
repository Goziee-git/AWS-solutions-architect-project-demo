# AWS Management Console Setup Guide
## EC2 + Application Load Balancer + WAF Demo

This guide provides step-by-step instructions to create the AWS EC2 + ALB + WAF architecture using the AWS Management Console.

## Architecture Overview

```
Internet → WAF → Application Load Balancer → EC2 Instances (Multi-AZ)
                                          ↓
                                    Auto Scaling Group
```

## Prerequisites

- AWS Account with appropriate permissions
- Basic understanding of AWS services
- SSH key pair for EC2 access

---

## Step 1: Create VPC and Networking

### 1.1 Create VPC
1. Navigate to **VPC Console** → **Your VPCs** → **Create VPC**
2. Configure:
   - **Name**: `ec2-alb-waf-demo-vpc`
   - **IPv4 CIDR**: `10.0.0.0/16`
   - **IPv6 CIDR**: No IPv6 CIDR block
   - **Tenancy**: Default
3. Click **Create VPC**

### 1.2 Create Internet Gateway
1. Go to **Internet Gateways** → **Create internet gateway**
2. Configure:
   - **Name**: `ec2-alb-waf-demo-igw`
3. Click **Create internet gateway**
4. **Attach to VPC**: Select your VPC and click **Attach internet gateway**

### 1.3 Create Subnets

#### Public Subnets (for ALB)
1. Go to **Subnets** → **Create subnet**
2. **Public Subnet 1**:
   - **VPC**: Select your VPC
   - **Name**: `ec2-alb-waf-demo-public-subnet-1`
   - **Availability Zone**: `us-east-1a` (or your preferred AZ)
   - **IPv4 CIDR**: `10.0.1.0/24`
3. **Public Subnet 2**:
   - **Name**: `ec2-alb-waf-demo-public-subnet-2`
   - **Availability Zone**: `us-east-1b` (different from subnet 1)
   - **IPv4 CIDR**: `10.0.2.0/24`
4. Click **Create subnet**

#### Private Subnets (for EC2 instances)
1. **Private Subnet 1**:
   - **Name**: `ec2-alb-waf-demo-private-subnet-1`
   - **Availability Zone**: `us-east-1a`
   - **IPv4 CIDR**: `10.0.10.0/24`
2. **Private Subnet 2**:
   - **Name**: `ec2-alb-waf-demo-private-subnet-2`
   - **Availability Zone**: `us-east-1b`
   - **IPv4 CIDR**: `10.0.20.0/24`

### 1.4 Create NAT Gateways
1. Go to **NAT Gateways** → **Create NAT gateway**
2. **NAT Gateway 1**:
   - **Name**: `ec2-alb-waf-demo-nat-1`
   - **Subnet**: Select public subnet 1
   - **Connectivity type**: Public
   - **Elastic IP allocation**: Click **Allocate Elastic IP**
3. **NAT Gateway 2**:
   - **Name**: `ec2-alb-waf-demo-nat-2`
   - **Subnet**: Select public subnet 2
   - **Connectivity type**: Public
   - **Elastic IP allocation**: Click **Allocate Elastic IP**

### 1.5 Configure Route Tables

#### Public Route Table
1. Go to **Route Tables** → Find the main route table for your VPC
2. **Edit routes**:
   - **Destination**: `0.0.0.0/0`
   - **Target**: Internet Gateway (select your IGW)
3. **Edit subnet associations**: Associate both public subnets

#### Private Route Tables
1. **Create route table** for private subnet 1:
   - **Name**: `ec2-alb-waf-demo-private-rt-1`
   - **VPC**: Select your VPC
   - **Routes**: Add `0.0.0.0/0` → NAT Gateway 1
   - **Subnet associations**: Associate private subnet 1

2. **Create route table** for private subnet 2:
   - **Name**: `ec2-alb-waf-demo-private-rt-2`
   - **VPC**: Select your VPC
   - **Routes**: Add `0.0.0.0/0` → NAT Gateway 2
   - **Subnet associations**: Associate private subnet 2

---

## Step 2: Create Security Groups

### 2.1 ALB Security Group
1. Navigate to **EC2 Console** → **Security Groups** → **Create security group**
2. Configure:
   - **Name**: `ec2-alb-waf-demo-alb-sg`
   - **Description**: Security group for Application Load Balancer
   - **VPC**: Select your VPC
3. **Inbound rules**:
   - **Type**: HTTP, **Port**: 80, **Source**: `0.0.0.0/0`
   - **Type**: HTTPS, **Port**: 443, **Source**: `0.0.0.0/0`
4. **Outbound rules**: Keep default (All traffic)
5. Click **Create security group**

### 2.2 EC2 Security Group
1. **Create security group**:
   - **Name**: `ec2-alb-waf-demo-ec2-sg`
   - **Description**: Security group for EC2 instances
   - **VPC**: Select your VPC
2. **Inbound rules**:
   - **Type**: HTTP, **Port**: 80, **Source**: ALB Security Group
   - **Type**: Custom TCP, **Port**: 8080, **Source**: ALB Security Group
   - **Type**: SSH, **Port**: 22, **Source**: `10.0.0.0/16` (VPC CIDR)
3. Click **Create security group**

### 2.3 Bastion Security Group (Optional)
1. **Create security group**:
   - **Name**: `ec2-alb-waf-demo-bastion-sg`
   - **Description**: Security group for bastion host
   - **VPC**: Select your VPC
2. **Inbound rules**:
   - **Type**: SSH, **Port**: 22, **Source**: Your IP address
3. Click **Create security group**

### NOTE
In the case where you intend to connect to the ec2-instances in the private subnet, edit the inbound rule for the private ec2 instances in the private subnet to include the security group of the bastion Host. This will allow you to connect to the private ec2 instances from the bastion host.
Note: copy the SSH key pair file into the bastion host and use the private ip address of the ec2-instances in the private subnet to connect to it:
```[within-the-bastion-host]$ scp -i public-key-pair.pem hostname@private-ip-address```

---

## Step 3: Create Launch Template

### 3.1 Create IAM Role for EC2
1. Navigate to **IAM Console** → **Roles** → **Create role**
2. **Trusted entity**: AWS service → EC2
3. **Permissions**: Attach policies:
   - `CloudWatchAgentServerPolicy`
   - `AmazonSSMManagedInstanceCore`
4. **Role name**: `ec2-alb-waf-demo-role`
5. Click **Create role**

### 3.2 Create Launch Template
1. Navigate to **EC2 Console** → **Launch Templates** → **Create launch template**
2. Configure:
   - **Name**: `ec2-alb-waf-demo-template`
   - **Description**: Launch template for demo instances
3. **Application and OS Images**:
   - **AMI**: Amazon Linux 2 AMI (latest)
4. **Instance type**: `t3.micro`
5. **Key pair**: Select your existing key pair
6. **Network settings**:
   - **Security groups**: Select EC2 security group
7. **Advanced details**:
   - **IAM instance profile**: Select the role created above
   - **User data**: Copy and paste the following script:

```bash
#!/bin/bash

# Update system
yum update -y

# Install required packages
yum install -y httpd python3 python3-pip

# Install Python packages for web server
pip3 install flask requests

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Create a simple web application
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>EC2 + ALB + WAF Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
        .container { background-color: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { color: #232f3e; border-bottom: 2px solid #ff9900; padding-bottom: 10px; }
        .info { margin: 20px 0; }
        .info-item { margin: 10px 0; padding: 10px; background-color: #f8f9fa; border-left: 4px solid #ff9900; }
        .test-section { margin-top: 30px; padding: 20px; background-color: #e8f4fd; border-radius: 5px; }
        button { background-color: #ff9900; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin: 5px; }
        button:hover { background-color: #e88b00; }
        #results { margin-top: 20px; padding: 10px; background-color: #f8f9fa; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🚀 AWS EC2 + ALB + WAF Demo</h1>
        
        <div class="info">
            <div class="info-item"><strong>Instance ID:</strong> $INSTANCE_ID</div>
            <div class="info-item"><strong>Availability Zone:</strong> $AZ</div>
            <div class="info-item"><strong>Private IP:</strong> $PRIVATE_IP</div>
            <div class="info-item"><strong>Timestamp:</strong> <span id="timestamp"></span></div>
        </div>

        <div class="test-section">
            <h3>🔒 WAF Testing</h3>
            <p>Test the WAF protection by trying these potentially malicious requests:</p>
            <button onclick="testSQLInjection()">Test SQL Injection</button>
            <button onclick="testXSS()">Test XSS</button>
            <button onclick="testRateLimiting()">Test Rate Limiting</button>
            <button onclick="testNormalRequest()">Normal Request</button>
            <div id="results"></div>
        </div>

        <div class="test-section">
            <h3>⚖️ Load Balancer Testing</h3>
            <p>Refresh this page multiple times to see different instances serving requests.</p>
            <button onclick="location.reload()">Refresh Page</button>
            <button onclick="makeMultipleRequests()">Make 10 Requests</button>
        </div>
    </div>

    <script>
        // Update timestamp
        document.getElementById('timestamp').textContent = new Date().toLocaleString();

        function testSQLInjection() {
            fetch('/search?q=\' OR 1=1 --')
                .then(response => response.text())
                .then(data => updateResults('SQL Injection Test', data))
                .catch(error => updateResults('SQL Injection Test', 'Error: ' + error));
        }

        function testXSS() {
            fetch('/comment', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({comment: '<script>alert("XSS")</script>'})
            })
                .then(response => response.text())
                .then(data => updateResults('XSS Test', data))
                .catch(error => updateResults('XSS Test', 'Error: ' + error));
        }

        function testRateLimiting() {
            const promises = [];
            for (let i = 0; i < 100; i++) {
                promises.push(fetch('/api/data'));
            }
            Promise.allSettled(promises)
                .then(results => {
                    const blocked = results.filter(r => r.value && r.value.status === 403).length;
                    updateResults('Rate Limiting Test', \`Made 100 requests, \${blocked} were blocked\`);
                });
        }

        function testNormalRequest() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => updateResults('Normal Request', JSON.stringify(data, null, 2)))
                .catch(error => updateResults('Normal Request', 'Error: ' + error));
        }

        function makeMultipleRequests() {
            const results = [];
            const promises = [];
            
            for (let i = 0; i < 10; i++) {
                promises.push(
                    fetch('/api/instance-info')
                        .then(response => response.json())
                        .then(data => data.instance_id)
                );
            }
            
            Promise.all(promises)
                .then(instanceIds => {
                    const counts = {};
                    instanceIds.forEach(id => counts[id] = (counts[id] || 0) + 1);
                    updateResults('Load Balancer Test', 'Instance distribution: ' + JSON.stringify(counts, null, 2));
                });
        }

        function updateResults(testName, result) {
            const resultsDiv = document.getElementById('results');
            resultsDiv.innerHTML = \`<strong>\${testName}:</strong><br><pre>\${result}</pre>\`;
        }
    </script>
</body>
</html>
EOF

# Create Flask application for API endpoints
cat > /opt/webapp.py << 'EOF'
from flask import Flask, jsonify, request
import json
import requests
import os

app = Flask(__name__)

# Get instance metadata
def get_instance_metadata():
    try:
        instance_id = requests.get('http://169.254.169.254/latest/meta-data/instance-id', timeout=2).text
        az = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone', timeout=2).text
        private_ip = requests.get('http://169.254.169.254/latest/meta-data/local-ipv4', timeout=2).text
        return {
            'instance_id': instance_id,
            'availability_zone': az,
            'private_ip': private_ip
        }
    except:
        return {
            'instance_id': 'unknown',
            'availability_zone': 'unknown',
            'private_ip': 'unknown'
        }

@app.route('/api/status')
def status():
    return jsonify({
        'status': 'healthy',
        'service': 'ec2-alb-waf-demo',
        **get_instance_metadata()
    })

@app.route('/api/instance-info')
def instance_info():
    return jsonify(get_instance_metadata())

@app.route('/search')
def search():
    query = request.args.get('q', '')
    # This endpoint is intentionally vulnerable for WAF testing
    return jsonify({
        'query': query,
        'results': ['result1', 'result2', 'result3'],
        **get_instance_metadata()
    })

@app.route('/comment', methods=['POST'])
def comment():
    data = request.get_json()
    comment = data.get('comment', '') if data else ''
    # This endpoint is intentionally vulnerable for WAF testing
    return jsonify({
        'comment': comment,
        'status': 'received',
        **get_instance_metadata()
    })

@app.route('/api/data')
def api_data():
    return jsonify({
        'data': 'sample data',
        'timestamp': 'current_time',
        **get_instance_metadata()
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Start Flask application
nohup python3 /opt/webapp.py > /var/log/webapp.log 2>&1 &

# Create a systemd service for the Flask app
cat > /etc/systemd/system/webapp.service << EOF
[Unit]
Description=Demo Web Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt
ExecStart=/usr/bin/python3 /opt/webapp.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable webapp
systemctl start webapp

echo "User data script completed successfully" >> /var/log/user-data.log
```

8. Click **Create launch template**

---

## Step 4: Create EC2 Instances

### 4.1 Create EC2 Instances for the Demo

You can create EC2 instances in two ways:
1. **Using the Launch Template** (Recommended for consistency)
2. **Manual EC2 Instance Creation** (For learning purposes)

#### Option 1: Launch Instances from Template

1. Navigate to **EC2 Console** → **Launch Templates**
2. Select your launch template (`ec2-alb-waf-demo-template`)
3. Click **Actions** → **Launch instance from template**
4. **Instance 1 Configuration**:
   - **Number of instances**: 1
   - **Network settings**:
     - **Subnet**: Select `ec2-alb-waf-demo-private-subnet-1`
     - **Auto-assign public IP**: Disable
     - **Security groups**: Ensure EC2 security group is selected
   - **Advanced details**:
     - **IAM instance profile**: Ensure the role is selected
     - **User data**: Should be pre-filled from template
5. **Add tags**:
   - **Key**: Name, **Value**: `ec2-alb-waf-demo-instance-1`
   - **Key**: Environment, **Value**: `demo`
   - **Key**: Project, **Value**: `ec2-alb-waf`
6. Click **Launch instance**

7. **Instance 2 Configuration**:
   - Repeat the above steps but:
     - **Subnet**: Select `ec2-alb-waf-demo-private-subnet-2`
     - **Name tag**: `ec2-alb-waf-demo-instance-2`

#### Option 2: Manual EC2 Instance Creation

1. Navigate to **EC2 Console** → **Instances** → **Launch instances**

**Instance 1:**
2. **Name and tags**:
   - **Name**: `ec2-alb-waf-demo-instance-1`
   - **Additional tags**:
     - **Environment**: `demo`
     - **Project**: `ec2-alb-waf`

3. **Application and OS Images (Amazon Machine Image)**:
   - **Quick Start**: Amazon Linux
   - **Amazon Machine Image (AMI)**: Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
   - **Architecture**: 64-bit (x86)

4. **Instance type**: 
   - Select `t3.small` (not eligible for free tier)

5. **Key pair (login)**:
   - **Key pair name**: Select your existing key pair or create a new one
   - If creating new: **Key pair name**: `ec2-alb-waf-demo-key`

6. **Network settings**:
   - Click **Edit**
   - **VPC**: Select `ec2-alb-waf-demo-vpc`
   - **Subnet**: Select `ec2-alb-waf-demo-private-subnet-1`
   - **Auto-assign public IP**: Disable
   - **Firewall (security groups)**: Select existing security group
   - **Common security groups**: Select `ec2-alb-waf-demo-ec2-sg`

7. **Configure storage**:
   - **Root volume**: 8 GiB gp3 (default is fine)
   - **Encrypted**: Enable (recommended)

8. **Advanced details**:
   - **IAM instance profile**: Select `ec2-alb-waf-demo-role`
   - **Monitoring**: Enable detailed monitoring (optional)
   - **User data**: Copy and paste the user data script from the launch template section above

9. **Summary**: Review configuration and click **Launch instance**

**Instance 2:**
10. Repeat steps 1-9 with these changes:
    - **Name**: `ec2-alb-waf-demo-instance-2`
    - **Subnet**: Select `ec2-alb-waf-demo-private-subnet-2`

### 4.2 Verify EC2 Instance Setup

1. **Check Instance Status**:
   - Go to **EC2 Console** → **Instances**
   - Wait for both instances to show:
     - **Instance State**: Running
     - **Status Checks**: 2/2 checks passed

2. **Verify User Data Execution**:
   - Select an instance → **Actions** → **Monitor and troubleshoot** → **Get system log**
   - Look for "User data script completed successfully" message
   - Or connect to instance and check: `tail -f /var/log/user-data.log`

3. **Test Web Application**:
   - If you have a bastion host or VPN access:
   ```bash
   # Test Apache (port 80)
   curl http://[PRIVATE-IP-OF-INSTANCE]
   
   # Test Flask app (port 8080)
   curl http://[PRIVATE-IP-OF-INSTANCE]:8080/health
   curl http://[PRIVATE-IP-OF-INSTANCE]:8080/api/status
   ```

### 4.3 Create Bastion Host (Optional - for SSH access)

If you need to SSH into your private instances for troubleshooting:

1. **Launch Bastion Instance**:
   - **Name**: `ec2-alb-waf-demo-bastion`
   - **AMI**: Amazon Linux 2
   - **Instance type**: `t3.micro`
   - **Subnet**: Select a public subnet (`ec2-alb-waf-demo-public-subnet-1`)
   - **Auto-assign public IP**: Enable
   - **Security group**: Select `ec2-alb-waf-demo-bastion-sg`
   - **Key pair**: Same as your other instances

2. **Connect to Private Instances via Bastion**::
   ```bash
   # Copy your private key to bastion (not recommended for production)
   scp -i your-key.pem your-key.pem ec2-user@[BASTION-PUBLIC-IP]:~/.ssh/
   
   # SSH to bastion
   ssh -i your-key.pem ec2-user@[BASTION-PUBLIC-IP]
   
   # From bastion, SSH to private instance
   ssh -i ~/.ssh/your-key.pem ec2-user@[PRIVATE-INSTANCE-IP]
   ```

### 4.4 Troubleshooting EC2 Instance Issues

**Common Issues:**

1. **Instance fails to start**:
   - Check security group rules
   - Verify subnet has route to NAT gateway
   - Check IAM role permissions

2. **User data script fails**:
   - Check system logs: **Actions** → **Monitor and troubleshoot** → **Get system log**
   - Connect to instance and check: `/var/log/cloud-init-output.log`

3. **Web application not responding**:
   - Check if services are running:
     ```bash
     sudo systemctl status httpd
     sudo systemctl status webapp
     ```
   - Check application logs:
     ```bash
     sudo tail -f /var/log/webapp.log
     ```

4. **Cannot connect to instance**:
   - Verify security group allows SSH from your IP or bastion
   - Check if instance is in private subnet (needs bastion or VPN)
   - Ensure key pair is correct

**Useful Commands for Instance Management:**

```bash
# Check running services
sudo systemctl list-units --type=service --state=running

# Restart web application
sudo systemctl restart webapp

# Check disk space
df -h

# Check memory usage
free -h

# Check network connectivity
ping google.com

# Check if ports are listening
sudo netstat -tlnp | grep -E ':(80|8080)'

# View recent system logs
sudo journalctl -n 50
```

---

## Step 5: Create Application Load Balancer

### 5.1 Create Target Group
1. Navigate to **EC2 Console** → **Target Groups** → **Create target group**
2. Configure:
   - **Target type**: Instances
   - **Target group name**: `ec2-alb-waf-demo-tg`
   - **Protocol**: HTTP
   - **Port**: 80
   - **VPC**: Select your VPC
3. **Health checks**:
   - **Health check protocol**: HTTP
   - **Health check path**: `/health`
   - **Port**: 8080
   - **Healthy threshold**: 2
   - **Unhealthy threshold**: 2
   - **Timeout**: 5 seconds
   - **Interval**: 30 seconds
4. Click **Next** → **Create target group**

### 5.2 Register EC2 Instances with Target Group

If you created EC2 instances manually (not using Auto Scaling Group):

1. Navigate to **EC2 Console** → **Target Groups**
2. Select your target group (`ec2-alb-waf-demo-tg`)
3. Go to **Targets** tab → **Register targets**
4. **Available instances**: Select both EC2 instances you created
5. **Ports for the selected instances**: 80 (this should be pre-filled)
6. Click **Include as pending below**
7. Review the pending targets and click **Register pending targets**
8. Wait for the targets to show as **healthy** (this may take a few minutes)

**Note**: If using Auto Scaling Group (recommended), the instances will be automatically registered.

### 5.3 Create Application Load Balancer
1. Navigate to **Load Balancers** → **Create Load Balancer**
2. Select **Application Load Balancer**
3. Configure:
   - **Name**: `ec2-alb-waf-demo-alb`
   - **Scheme**: Internet-facing
   - **IP address type**: IPv4
4. **Network mapping**:
   - **VPC**: Select your VPC
   - **Mappings**: Select both public subnets
5. **Security groups**: Select ALB security group
6. **Listeners and routing**:
   - **Protocol**: HTTP
   - **Port**: 80
   - **Default action**: Forward to target group created above
7. Click **Create load balancer**

---

## Step 6: Create Auto Scaling Group

### 6.1 Create Auto Scaling Group
1. Navigate to **Auto Scaling Groups** → **Create Auto Scaling group**
2. **Step 1 - Choose launch template**:
   - **Name**: `ec2-alb-waf-demo-asg`
   - **Launch template**: Select your launch template
   - **Version**: Latest
3. **Step 2 - Choose instance launch options**:
   - **VPC**: Select your VPC
   - **Subnets**: Select both private subnets
4. **Step 3 - Configure advanced options**:
   - **Load balancing**: Attach to an existing load balancer
   - **Target groups**: Select your target group
   - **Health checks**: ELB health checks
   - **Health check grace period**: 300 seconds
5. **Step 4 - Configure group size and scaling policies**:
   - **Desired capacity**: 2
   - **Minimum capacity**: 2
   - **Maximum capacity**: 4
   - **Scaling policies**: Target tracking scaling policy
     - **Metric type**: Average CPU Utilization
     - **Target value**: 70
6. **Step 5 - Add notifications**: Skip
7. **Step 6 - Add tags**:
   - **Key**: Name, **Value**: `ec2-alb-waf-demo-instance`
8. **Step 7 - Review**: Click **Create Auto Scaling group**

---

## Step 7: Create and Configure WAF

### 7.1 Create Web ACL
1. Navigate to **WAF & Shield Console** → **Web ACLs** → **Create web ACL**
2. **Step 1 - Describe web ACL**:
   - **Name**: `ec2-alb-waf-demo-waf`
   - **Description**: WAF for EC2 ALB demo
   - **Resource type**: Regional resources (ALB, API Gateway, etc.)
   - **Region**: Same as your ALB region
3. **Step 2 - Add rules and rule groups**:

#### Rule 1: AWS Managed Core Rule Set
- Click **Add rules** → **Add managed rule groups**
- **AWS managed rule groups**:
  - Select **Core rule set**
  - **Action**: Block
  - **Priority**: 1

#### Rule 2: AWS Managed Known Bad Inputs
- Add **Known bad inputs**
- **Action**: Block
- **Priority**: 2

#### Rule 3: AWS Managed SQL Injection Rule Set
- Add **SQL database**
- **Action**: Block
- **Priority**: 3

#### Rule 4: Rate Limiting Rule
- Click **Add rules** → **Add my own rules and rule groups**
- **Rule type**: Rate-based rule
- **Name**: `RateLimitRule`
- **Rate limit**: 2000 requests per 5 minutes
- **IP address to use for rate limiting**: Source IP address
- **Action**: Block
- **Priority**: 4

#### Rule 5: Block Bad User Agents
- **Rule type**: Regular rule
- **Name**: `BlockBadUserAgents`
- **Statement**:
  - **Inspect**: Single header → Header field name: `user-agent`
  - **Match type**: Contains string
  - **String to match**: `badbot`
  - **Text transformation**: Lowercase
- **Action**: Block
- **Priority**: 5

#### Rule 6: Block Admin Paths
- **Rule type**: Regular rule
- **Name**: `BlockAdminPaths`
- **Statement**:
  - **Inspect**: URI path
  - **Match type**: Starts with string
  - **String to match**: `/admin`
  - **Text transformation**: Lowercase
- **Action**: Block
- **Priority**: 6

4. **Step 3 - Set rule priority**: Verify rule priorities
5. **Step 4 - Configure metrics**: Enable CloudWatch metrics
6. **Step 5 - Review and create**: Click **Create web ACL**

### 7.2 Associate WAF with ALB
1. In the Web ACL details page, go to **Associated AWS resources**
2. Click **Add AWS resources**
3. **Resource type**: Application Load Balancer
4. Select your ALB
5. Click **Add**

---

## Step 8: Create S3 Bucket for ALB Logs (Optional)

### 8.1 Create S3 Bucket
1. Navigate to **S3 Console** → **Create bucket**
2. Configure:
   - **Bucket name**: `ec2-alb-waf-demo-logs-[random-suffix]`
   - **Region**: Same as your ALB
   - **Block all public access**: Keep enabled
3. Click **Create bucket**

### 8.2 Configure ALB Access Logs
1. Go back to **EC2 Console** → **Load Balancers**
2. Select your ALB → **Attributes** tab
3. Click **Edit**
4. **Access logs**:
   - Enable access logs
   - **S3 location**: Select your S3 bucket
   - **Prefix**: `alb-logs`
5. Click **Save changes**

---

## Step 9: Testing the Setup

### 9.1 Basic Connectivity Test
1. Get your ALB DNS name from the Load Balancer details
2. Open a web browser and navigate to: `http://[ALB-DNS-NAME]`
3. You should see the demo web application

### 9.2 Load Balancer Testing
1. Refresh the page multiple times
2. Check the instance information to see different instances serving requests
3. Use the "Make 10 Requests" button to test load distribution

### 9.3 WAF Testing
1. **SQL Injection Test**: Click "Test SQL Injection" button
2. **XSS Test**: Click "Test XSS" button
3. **Rate Limiting**: Click "Test Rate Limiting" button
4. **Manual Tests**:
   - Try accessing: `http://[ALB-DNS-NAME]/admin` (should be blocked)
   - Use curl with bad user agent: `curl -H "User-Agent: badbot" http://[ALB-DNS-NAME]`

### 9.4 Monitor WAF Activity
1. Go to **WAF Console** → Your Web ACL → **Overview**
2. Check **Sampled requests** to see blocked requests
3. View **Metrics** for rule effectiveness

### 9.5 Monitor ALB Health
1. Go to **EC2 Console** → **Target Groups** → Your target group
2. Check **Targets** tab to see healthy instances
3. View **Monitoring** tab for metrics

---

## Step 10: CloudWatch Monitoring (Optional)

### 10.1 Create CloudWatch Dashboard
1. Navigate to **CloudWatch Console** → **Dashboards** → **Create dashboard**
2. **Dashboard name**: `EC2-ALB-WAF-Demo`
3. Add widgets for:
   - ALB request count
   - ALB response time
   - WAF blocked requests
   - EC2 CPU utilization
   - Auto Scaling group metrics

### 10.2 Set up CloudWatch Alarms
1. **High CPU Alarm**:
   - **Metric**: EC2 → By Auto Scaling Group → CPUUtilization
   - **Threshold**: > 70%
   - **Action**: Send notification or trigger scaling

2. **ALB High Response Time**:
   - **Metric**: ApplicationELB → TargetResponseTime
   - **Threshold**: > 1 second
   - **Action**: Send notification

---

## Step 11: Cleanup Instructions

When you're done testing, clean up resources in this order:

1. **Delete Auto Scaling Group**
2. **Delete Launch Template**
3. **Delete Load Balancer**
4. **Delete Target Group**
5. **Delete WAF Web ACL**
6. **Terminate any remaining EC2 instances**
7. **Delete NAT Gateways**
8. **Release Elastic IPs**
9. **Delete Route Tables** (custom ones)
10. **Delete Subnets**
11. **Delete Internet Gateway** (detach first)
12. **Delete VPC**
13. **Delete Security Groups**
14. **Delete S3 Bucket** (empty first)
15. **Delete IAM Role**

---

## Troubleshooting

### Common Issues

1. **Instances not healthy in target group**:
   - Check security group rules
   - Verify health check path (`/health`)
   - Check instance logs: `/var/log/user-data.log`

2. **WAF not blocking requests**:
   - Verify WAF is associated with ALB
   - Check rule priorities and actions
   - Review sampled requests in WAF console

3. **Load balancer not accessible**:
   - Check security group allows HTTP/HTTPS
   - Verify subnets are public
   - Ensure internet gateway is attached

4. **Auto Scaling not working**:
   - Check IAM permissions
   - Verify launch template configuration
   - Review CloudWatch alarms

### Useful Commands for Testing

```bash
# Test basic connectivity
curl http://[ALB-DNS-NAME]

# Test health endpoint
curl http://[ALB-DNS-NAME]/health

# Test API endpoints
curl http://[ALB-DNS-NAME]/api/status
curl http://[ALB-DNS-NAME]/api/instance-info

# Test WAF SQL injection protection
curl "http://[ALB-DNS-NAME]/search?q=' OR 1=1 --"

# Test WAF XSS protection
curl -X POST -H "Content-Type: application/json" \
  -d '{"comment":"<script>alert(\"XSS\")</script>"}' \
  http://[ALB-DNS-NAME]/comment

# Test bad user agent blocking
curl -H "User-Agent: badbot" http://[ALB-DNS-NAME]

# Test admin path blocking
curl http://[ALB-DNS-NAME]/admin
```

---

## Security Best Practices Implemented

1. **Network Security**:
   - Private subnets for EC2 instances
   - Security groups with least privilege
   - NAT gateways for outbound internet access

2. **Application Security**:
   - WAF protection against OWASP Top 10
   - Rate limiting to prevent DDoS
   - Input validation and sanitization

3. **Infrastructure Security**:
   - IAM roles with minimal permissions
   - Encrypted communication where possible
   - Access logging for audit trails

4. **Monitoring and Alerting**:
   - CloudWatch metrics and alarms
   - WAF request sampling
   - ALB access logs

This setup provides a robust, scalable, and secure web application architecture following AWS best practices.
