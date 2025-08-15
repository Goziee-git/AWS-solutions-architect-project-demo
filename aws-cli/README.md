# AWS Simple Architecture Project

This project demonstrates how to provision a complete AWS infrastructure using both **AWS CLI** and **Terraform**. It's designed to be beginner-friendly while showcasing best practices for Infrastructure as Code (IaC).

## 🏗️ Architecture Overview

![Architecture Diagram](generated-diagrams/architecture-diagram.png)

### Infrastructure Components:
- **Custom VPC** (10.0.0.0/16) with DNS support
- **Public Subnet** (10.0.1.0/24) with internet access
- **Private Subnet** (10.0.2.0/24) for backend resources
- **Internet Gateway** for public internet connectivity
- **Route Table** with proper routing configuration
- **Security Group** with HTTP, HTTPS, and SSH access
- **Custom AMI** with pre-configured Apache web server
- **EC2 Instance** running the web application

## 📁 Project Structure

```
aws-cli/
├── 📄 README.md                    # This file - project overview
├── 📄 cli-README.md                # Detailed AWS CLI guide
├── 📄 terraform-README.md          # Detailed Terraform guide
├── 📄 project-structure.md         # Project structure overview
├── 🖼️ generated-diagrams/          # Architecture diagrams
│   └── architecture-diagram.png
├── 📁 cli-scripts/                 # AWS CLI implementation
│   ├── variables.sh                # Configuration variables
│   ├── 01-create-vpc.sh           # Create VPC
│   ├── 02-create-subnets.sh       # Create subnets
│   ├── 03-create-igw.sh           # Create Internet Gateway
│   ├── 04-create-route-table.sh   # Configure routing
│   ├── 05-create-security-group.sh # Create security group
│   ├── 06-create-ami.sh           # Create custom AMI
│   ├── 07-launch-ec2.sh           # Launch EC2 instance
│   └── cleanup.sh                 # Clean up resources
└── 📁 terraform/                   # Terraform implementation
    ├── main.tf                     # Main configuration
    ├── variables.tf                # Variable definitions
    ├── outputs.tf                  # Output definitions
    ├── vpc.tf                      # VPC resources
    ├── subnets.tf                  # Subnet resources
    ├── security.tf                 # Security groups
    ├── compute.tf                  # EC2 resources
    ├── user_data.sh               # Instance initialization script
    └── terraform.tfvars.example    # Example variables file
```

## 🚀 Quick Start

### Choose Your Approach:

#### Option 1: AWS CLI (Imperative)
```bash
cd cli-scripts
source variables.sh
./01-create-vpc.sh && ./02-create-subnets.sh && ./03-create-igw.sh && ./04-create-route-table.sh && ./05-create-security-group.sh && ./06-create-ami.sh && ./07-launch-ec2.sh
```

#### Option 2: Terraform (Declarative)
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
terraform init
terraform plan
terraform apply
```

## 📋 Prerequisites

### Required Tools:
- **AWS CLI v2** - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform** (for Terraform approach) - [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)

### AWS Setup:
1. **AWS Account** with appropriate permissions
2. **AWS CLI configured** with credentials
3. **EC2 Key Pair** for SSH access

### Quick AWS Setup:
```bash
# Install AWS CLI (Linux)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Configure credentials
aws configure

# Create key pair
aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > ~/.ssh/my-key-pair.pem
chmod 400 ~/.ssh/my-key-pair.pem
```

## 🎯 Learning Objectives

This project teaches:

### AWS Services:
- **VPC** - Virtual Private Cloud networking
- **EC2** - Elastic Compute Cloud instances
- **AMI** - Amazon Machine Images
- **Security Groups** - Virtual firewalls
- **Route Tables** - Network routing
- **Internet Gateway** - Internet connectivity

### Infrastructure as Code:
- **AWS CLI** - Imperative infrastructure management
- **Terraform** - Declarative infrastructure management
- **State Management** - Tracking infrastructure changes
- **Best Practices** - Security, tagging, documentation

### DevOps Concepts:
- **Automation** - Scripted infrastructure deployment
- **Reproducibility** - Consistent environment creation
- **Documentation** - Self-documenting infrastructure
- **Cleanup** - Resource lifecycle management

## 📊 Cost Breakdown

### Estimated Monthly Costs (us-east-1):
| Resource | Cost | Notes |
|----------|------|-------|
| VPC, Subnets, IGW | **Free** | No charges for basic networking |
| Security Groups | **Free** | No charges for security groups |
| Route Tables | **Free** | No charges for route tables |
| AMI Storage | **~$0.05/month** | 8GB EBS snapshot |
| EC2 t2.micro | **~$8.50/month** | **Free tier: 750 hours/month** |
| Data Transfer | **$0.09/GB** | First 1GB free monthly |

**Total: ~$8.55/month** (or **FREE** with AWS Free Tier)

## 🔒 Security Features

### Built-in Security:
- **VPC Isolation** - Private network environment
- **Security Groups** - Stateful firewall rules
- **Encrypted EBS** - Encrypted root volumes (Terraform)
- **SSH Key Authentication** - No password authentication
- **Minimal Attack Surface** - Only necessary ports open

### Security Best Practices:
- Restrict SSH access to your IP only
- Use IAM roles instead of access keys when possible
- Enable CloudTrail for audit logging
- Regular security updates via user data scripts

## 🛠️ Customization Options

### Network Configuration:
```bash
# CLI: Edit cli-scripts/variables.sh
export VPC_CIDR="10.0.0.0/16"
export PUBLIC_SUBNET_CIDR="10.0.1.0/24"
export PRIVATE_SUBNET_CIDR="10.0.2.0/24"

# Terraform: Edit terraform.tfvars
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
```

### Instance Configuration:
```bash
# CLI: Edit cli-scripts/variables.sh
export INSTANCE_TYPE="t2.micro"
export KEY_PAIR_NAME="your-key-pair"

# Terraform: Edit terraform.tfvars
instance_type = "t2.micro"
key_pair_name = "your-key-pair"
```

### Security Configuration:
```bash
# Restrict SSH to your IP only
# CLI: Modify 05-create-security-group.sh
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr ${MY_IP}/32

# Terraform: Edit terraform.tfvars
allowed_ssh_cidr = "YOUR.IP.ADDRESS/32"
```

## 🧪 Testing and Verification

### Automated Tests:
```bash
# Test web server
curl http://$(terraform output -raw instance_public_ip)

# Test SSH connectivity
ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw instance_public_ip)

# Verify security groups
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)
```

### Manual Verification:
1. **AWS Console** - Verify resources in AWS Management Console
2. **Web Browser** - Access the web application
3. **SSH Connection** - Connect to the instance
4. **CloudWatch** - Monitor instance metrics

## 🧹 Cleanup

### AWS CLI Cleanup:
```bash
cd cli-scripts
./cleanup.sh
```

### Terraform Cleanup:
```bash
cd terraform
terraform destroy
```

### Verification:
```bash
# Verify no resources remain
aws ec2 describe-instances --filters "Name=tag:Project,Values=aws-simple-architecture"
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=aws-simple-architecture"
```

## 🆚 CLI vs Terraform Comparison

| Aspect | AWS CLI | Terraform |
|--------|---------|-----------|
| **Learning Curve** | Easier to start | Steeper initially |
| **State Management** | Manual | Automatic |
| **Idempotency** | Manual checks | Built-in |
| **Team Collaboration** | Difficult | Excellent |
| **Rollback** | Manual scripts | `terraform destroy` |
| **Documentation** | External docs | Self-documenting |
| **Dependency Management** | Manual ordering | Automatic |
| **Best For** | Learning, debugging | Production, teams |

## 🎓 Next Steps

### Beginner:
1. Deploy the basic architecture
2. Explore AWS Console to understand resources
3. Modify security group rules
4. Try different instance types

### Intermediate:
1. Add a NAT Gateway for private subnet internet access
2. Implement Auto Scaling Groups
3. Add an Application Load Balancer
4. Set up CloudWatch monitoring and alarms

### Advanced:
1. Multi-AZ deployment for high availability
2. RDS database in private subnet
3. CI/CD pipeline with GitHub Actions
4. Infrastructure testing with Terratest
5. Cost optimization with Spot Instances

## 📚 Learning Resources

### AWS Documentation:
- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)

### Terraform Resources:
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)

### AWS Architecture:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)

## 🤝 Contributing

Feel free to:
- Report issues or bugs
- Suggest improvements
- Add new features
- Improve documentation

## 📄 License

This project is provided as-is for educational purposes. Use at your own risk and always follow AWS security best practices.

## ⚠️ Important Notes

1. **Costs**: Always monitor your AWS costs and clean up resources when done
2. **Security**: Never commit AWS credentials to version control
3. **Regions**: Some resources may not be available in all AWS regions
4. **Limits**: Be aware of AWS service limits and quotas
5. **Best Practices**: This is a learning project - production deployments should include additional security and monitoring

---

**Happy Learning! 🎉**

For detailed instructions, see:
- [CLI Implementation Guide](cli-README.md)
- [Terraform Implementation Guide](terraform-README.md)
