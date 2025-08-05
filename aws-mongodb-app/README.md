# AWS MongoDB Application - Multi-AZ Deployment

A full-stack web application with React frontend, Node.js backend, and MongoDB database deployed across multiple Availability Zones on AWS for high availability and fault tolerance.

## Architecture Overview

![AWS MongoDB Architecture](./generated-diagrams/aws-mongodb-architecture.png)

### Architecture Components

- **Frontend**: React application running on EC2 instances
- **Backend**: Node.js/Express API servers running on EC2 instances  
- **Database**: MongoDB running on EC2 instances with replication
- **Load Balancer**: Application Load Balancer for traffic distribution
- **Network**: VPC with public/private subnets across 2 AZs
- **Security**: Security groups for network access control
- **Monitoring**: CloudWatch for logging and monitoring

## Prerequisites

Before deploying this application, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **EC2 Key Pair** created in your target region
4. **Docker** and **Docker Compose** (for local development)
5. **Git** for version control
6. **Node.js 18+** (for local development)

## Project Structure

```
aws-mongodb-app/
├── backend/                    # Node.js API server
│   ├── config/                # Database configuration
│   ├── middleware/            # Authentication & authorization
│   ├── models/               # MongoDB data models
│   ├── routes/               # API route handlers
│   ├── Dockerfile            # Backend container configuration
│   ├── package.json          # Backend dependencies
│   └── server.js             # Main server file
├── frontend/                  # React application
│   ├── src/                  # React source code
│   ├── public/               # Static assets
│   ├── Dockerfile            # Frontend container configuration
│   └── package.json          # Frontend dependencies
├── aws/                      # AWS CloudFormation templates
│   ├── cloudformation.yaml   # Main infrastructure template
│   └── ec2-instances.yaml    # EC2 instances template
├── mongodb/                  # MongoDB configuration
│   └── init-scripts/         # Database initialization
├── nginx/                    # Load balancer configuration
├── docker-compose.yml        # Local development setup
└── README.md                 # This file
```

## Local Development Setup

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd aws-mongodb-app
```

### 2. Environment Configuration

Copy the environment template and configure your settings:

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env` with your configuration:

```env
NODE_ENV=development
PORT=5000
MONGODB_URI=mongodb://admin:password123@mongodb:27017/myapp?authSource=admin
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d
FRONTEND_URL=http://localhost:3000
```

### 3. Start Local Development Environment

```bash
# Start all services with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### 4. Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **API Health Check**: http://localhost:5000/health
- **MongoDB**: localhost:27017

## AWS Deployment Guide

### Step 1: Prepare AWS Environment

#### 1.1 Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format
```

#### 1.2 Create EC2 Key Pair

```bash
# Create a new key pair
aws ec2 create-key-pair --key-name mongodb-app-key --query 'KeyMaterial' --output text > mongodb-app-key.pem

# Set appropriate permissions
chmod 400 mongodb-app-key.pem
```

### Step 2: Deploy Infrastructure

#### 2.1 Deploy VPC and Networking

```bash
# Deploy the main infrastructure
aws cloudformation create-stack \
  --stack-name mongodb-app-infrastructure \
  --template-body file://aws/cloudformation.yaml \
  --parameters ParameterKey=EnvironmentName,ParameterValue=mongodb-app \
               ParameterKey=KeyPairName,ParameterValue=mongodb-app-key \
  --capabilities CAPABILITY_IAM

# Wait for stack creation to complete
aws cloudformation wait stack-create-complete --stack-name mongodb-app-infrastructure
```

#### 2.2 Deploy EC2 Instances

```bash
# Deploy EC2 instances
aws cloudformation create-stack \
  --stack-name mongodb-app-instances \
  --template-body file://aws/ec2-instances.yaml \
  --parameters ParameterKey=EnvironmentName,ParameterValue=mongodb-app \
               ParameterKey=KeyPairName,ParameterValue=mongodb-app-key \
               ParameterKey=InstanceType,ParameterValue=t3.medium \
  --capabilities CAPABILITY_IAM

# Wait for stack creation to complete
aws cloudformation wait stack-create-complete --stack-name mongodb-app-instances
```

### Step 3: Configure Application Deployment

#### 3.1 Get Bastion Host IP

```bash
# Get the bastion host public IP
BASTION_IP=$(aws cloudformation describe-stacks \
  --stack-name mongodb-app-instances \
  --query 'Stacks[0].Outputs[?OutputKey==`BastionHostIP`].OutputValue' \
  --output text)

echo "Bastion Host IP: $BASTION_IP"
```

#### 3.2 Get Load Balancer URL

```bash
# Get the load balancer URL
ALB_URL=$(aws cloudformation describe-stacks \
  --stack-name mongodb-app-infrastructure \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text)

echo "Application URL: $ALB_URL"
```

### Step 4: Deploy Application Code

#### 4.1 Create Application Repository

```bash
# Create a Git repository for your application code
git init
git add .
git commit -m "Initial commit"

# Push to your Git repository (GitHub, GitLab, etc.)
git remote add origin <your-git-repository-url>
git push -u origin main
```

#### 4.2 SSH to Instances via Bastion

```bash
# SSH to bastion host
ssh -i mongodb-app-key.pem ec2-user@$BASTION_IP

# From bastion, SSH to private instances
# Get private IPs from AWS console or CLI
ssh ec2-user@<private-ip-of-instance>
```

#### 4.3 Deploy to Each Instance Type

**For Database Servers:**

```bash
# SSH to database instances
sudo yum update -y
sudo yum install -y docker git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone and start MongoDB
git clone <your-repository-url> aws-mongodb-app
cd aws-mongodb-app
docker-compose up -d mongodb
```

**For Backend API Servers:**

```bash
# SSH to API instances
sudo yum update -y
sudo yum install -y docker git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone and start backend
git clone <your-repository-url> aws-mongodb-app
cd aws-mongodb-app

# Update environment variables for production
cp backend/.env.example backend/.env
# Edit backend/.env with production MongoDB connection string

docker-compose up -d backend
```

**For Frontend Web Servers:**

```bash
# SSH to frontend instances
sudo yum update -y
sudo yum install -y docker git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone and start frontend
git clone <your-repository-url> aws-mongodb-app
cd aws-mongodb-app
docker-compose up -d frontend
```

### Step 5: Configure MongoDB Replication

#### 5.1 Initialize MongoDB Replica Set

```bash
# SSH to primary MongoDB instance
docker exec -it mongodb mongo -u admin -p password123 --authenticationDatabase admin

# Initialize replica set
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "<primary-mongodb-private-ip>:27017" },
    { _id: 1, host: "<secondary-mongodb-private-ip>:27017" }
  ]
})

# Check replica set status
rs.status()
```

### Step 6: Update Security Groups

#### 6.1 Configure Application Communication

```bash
# Allow backend to communicate with MongoDB
aws ec2 authorize-security-group-ingress \
  --group-id <database-security-group-id> \
  --protocol tcp \
  --port 27017 \
  --source-group <api-security-group-id>

# Allow frontend to communicate with backend
aws ec2 authorize-security-group-ingress \
  --group-id <api-security-group-id> \
  --protocol tcp \
  --port 5000 \
  --source-group <web-security-group-id>
```

## Configuration Details

### Environment Variables

#### Backend Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `production` |
| `PORT` | Server port | `5000` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://user:pass@host:27017/db` |
| `JWT_SECRET` | JWT signing secret | `your-secret-key` |
| `JWT_EXPIRE` | JWT expiration time | `7d` |
| `FRONTEND_URL` | Frontend URL for CORS | `http://frontend-url` |

#### Frontend Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `REACT_APP_API_URL` | Backend API URL | `http://api-url/api` |

### Security Groups Configuration

#### Load Balancer Security Group
- **Inbound**: Port 80 (HTTP) and 443 (HTTPS) from 0.0.0.0/0
- **Outbound**: All traffic

#### Web Server Security Group
- **Inbound**: Port 3000 from Load Balancer SG, Port 22 from Bastion SG
- **Outbound**: All traffic

#### API Server Security Group
- **Inbound**: Port 5000 from Load Balancer SG and Web Server SG, Port 22 from Bastion SG
- **Outbound**: All traffic

#### Database Security Group
- **Inbound**: Port 27017 from API Server SG, Port 22 from Bastion SG
- **Outbound**: All traffic

#### Bastion Security Group
- **Inbound**: Port 22 from 0.0.0.0/0
- **Outbound**: All traffic

## Monitoring and Logging

### CloudWatch Configuration

#### 1. Install CloudWatch Agent

```bash
# On each EC2 instance
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
```

#### 2. Configure CloudWatch Agent

Create `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`:

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "mongodb-app-system-logs",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "MongoDB-App",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
```

#### 3. Start CloudWatch Agent

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
```

### Application Health Checks

The application includes built-in health check endpoints:

- **Backend Health**: `GET /health`
- **Database Health**: Included in backend health check
- **Frontend Health**: Served by nginx with custom health page

## Backup and Recovery

### Database Backup Strategy

#### 1. Automated Backups with Cron

```bash
# Create backup script
cat > /home/ec2-user/backup-mongodb.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/ec2-user/backups"
mkdir -p $BACKUP_DIR

# Create MongoDB dump
docker exec mongodb mongodump --host localhost --port 27017 \
  --username admin --password password123 --authenticationDatabase admin \
  --out $BACKUP_DIR/mongodb_backup_$DATE

# Upload to S3 (optional)
# aws s3 cp $BACKUP_DIR/mongodb_backup_$DATE s3://your-backup-bucket/ --recursive

# Keep only last 7 days of backups
find $BACKUP_DIR -type d -name "mongodb_backup_*" -mtime +7 -exec rm -rf {} \;
EOF

chmod +x /home/ec2-user/backup-mongodb.sh

# Add to crontab for daily backups at 2 AM
echo "0 2 * * * /home/ec2-user/backup-mongodb.sh" | crontab -
```

#### 2. Point-in-Time Recovery

```bash
# Restore from backup
docker exec -it mongodb mongorestore --host localhost --port 27017 \
  --username admin --password password123 --authenticationDatabase admin \
  --drop /path/to/backup/directory
```

## Scaling and Performance

### Horizontal Scaling

#### 1. Auto Scaling Groups

Create Auto Scaling Groups for each tier:

```bash
# Create launch template for web servers
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name mongodb-app-web-asg \
  --launch-template LaunchTemplateName=mongodb-app-web-lt \
  --min-size 2 \
  --max-size 6 \
  --desired-capacity 2 \
  --vpc-zone-identifier "subnet-xxx,subnet-yyy" \
  --target-group-arns arn:aws:elasticloadbalancing:region:account:targetgroup/mongodb-app-web-tg
```

#### 2. Database Scaling

For MongoDB scaling:
- **Read Replicas**: Add more secondary nodes
- **Sharding**: Implement MongoDB sharding for horizontal scaling
- **Connection Pooling**: Configure connection pooling in the application

### Performance Optimization

#### 1. Database Optimization

```javascript
// Add indexes for better query performance
db.users.createIndex({ "email": 1 }, { unique: true })
db.users.createIndex({ "username": 1 }, { unique: true })
db.products.createIndex({ "name": "text", "description": "text" })
db.products.createIndex({ "category": 1 })
db.products.createIndex({ "price": 1 })
```

#### 2. Application Optimization

- **Caching**: Implement Redis for session and data caching
- **CDN**: Use CloudFront for static asset delivery
- **Compression**: Enable gzip compression in nginx
- **Connection Pooling**: Configure MongoDB connection pooling

## Security Best Practices

### 1. Network Security

- **VPC**: All resources deployed in private subnets
- **Security Groups**: Principle of least privilege
- **NACLs**: Additional network-level security
- **Bastion Host**: Secure SSH access to private instances

### 2. Application Security

- **HTTPS**: SSL/TLS encryption for all communications
- **Authentication**: JWT-based authentication
- **Input Validation**: Server-side input validation
- **Rate Limiting**: API rate limiting to prevent abuse
- **CORS**: Proper CORS configuration

### 3. Database Security

- **Authentication**: MongoDB authentication enabled
- **Encryption**: Data encryption at rest and in transit
- **Network Isolation**: Database in private subnets only
- **Backup Encryption**: Encrypted backups

### 4. Infrastructure Security

- **IAM Roles**: Least privilege IAM roles for EC2 instances
- **Security Updates**: Regular security updates
- **Monitoring**: CloudWatch monitoring and alerting
- **Secrets Management**: AWS Secrets Manager for sensitive data

## Troubleshooting

### Common Issues

#### 1. Application Not Accessible

```bash
# Check load balancer health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check security groups
aws ec2 describe-security-groups --group-ids <security-group-id>

# Check instance status
aws ec2 describe-instances --instance-ids <instance-id>
```

#### 2. Database Connection Issues

```bash
# Check MongoDB status
docker ps | grep mongodb
docker logs mongodb

# Test database connectivity
docker exec -it mongodb mongo -u admin -p password123 --authenticationDatabase admin

# Check network connectivity
telnet <mongodb-private-ip> 27017
```

#### 3. Application Errors

```bash
# Check application logs
docker logs backend
docker logs frontend

# Check system logs
sudo tail -f /var/log/messages

# Check CloudWatch logs
aws logs describe-log-groups
aws logs get-log-events --log-group-name <log-group-name> --log-stream-name <log-stream-name>
```

### Performance Issues

#### 1. High CPU Usage

```bash
# Check CPU usage
top
htop

# Check Docker container resources
docker stats

# Scale up instances if needed
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name <asg-name> \
  --desired-capacity <new-capacity>
```

#### 2. Database Performance

```bash
# Check MongoDB performance
docker exec -it mongodb mongo -u admin -p password123 --authenticationDatabase admin
db.runCommand({serverStatus: 1})
db.stats()

# Check slow queries
db.setProfilingLevel(2)
db.system.profile.find().sort({ts: -1}).limit(5)
```

## Cost Optimization

### 1. Instance Right-Sizing

- Monitor CloudWatch metrics to identify underutilized instances
- Use AWS Compute Optimizer recommendations
- Consider Reserved Instances for predictable workloads

### 2. Storage Optimization

- Use GP3 volumes instead of GP2 for better price/performance
- Implement lifecycle policies for log retention
- Use S3 for backup storage with appropriate storage classes

### 3. Network Optimization

- Use VPC endpoints to reduce NAT Gateway costs
- Optimize data transfer between AZs
- Consider CloudFront for static content delivery

## Maintenance

### Regular Maintenance Tasks

#### Weekly Tasks
- Review CloudWatch metrics and alarms
- Check application and system logs
- Verify backup integrity
- Update security patches

#### Monthly Tasks
- Review and optimize costs
- Update application dependencies
- Performance testing
- Security audit

#### Quarterly Tasks
- Disaster recovery testing
- Capacity planning review
- Security penetration testing
- Architecture review

## Support and Documentation

### Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [MongoDB Best Practices](https://docs.mongodb.com/manual/administration/production-notes/)
- [Node.js Production Best Practices](https://expressjs.com/en/advanced/best-practice-performance.html)
- [React Production Build](https://create-react-app.dev/docs/production-build/)

### Getting Help

1. **AWS Support**: Use AWS Support for infrastructure issues
2. **Application Issues**: Check application logs and CloudWatch metrics
3. **Database Issues**: Refer to MongoDB documentation and logs
4. **Community**: Stack Overflow, AWS forums, MongoDB community

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

---

**Note**: Remember to replace placeholder values (like repository URLs, IP addresses, and security group IDs) with your actual values when deploying this application.
