# Three-Tier Architecture CloudFormation Template

This document explains the parameters in the CloudFormation template (`three-tier-architecture.yaml`) that need to be replaced with real values when deploying the stack.

## Getting Started with CloudFormation

### Prerequisites
- An AWS account with appropriate permissions
- AWS CLI installed and configured (for CLI deployment)
- Basic understanding of AWS services (VPC, EC2, RDS)
- The CloudFormation template file (`three-tier-architecture.yaml`)

### Deployment Methods

#### Option 1: AWS Management Console
1. Sign in to the AWS Management Console
2. Navigate to CloudFormation service
3. Click "Create stack" > "With new resources (standard)"
4. Choose "Upload a template file" and select `three-tier-architecture.yaml`
5. Click "Next" and provide a stack name (e.g., "ThreeTierArchitecture")
6. Fill in the required parameters (at minimum: KeyName and DBPassword)
7. Click "Next" through the stack options page
8. Review the configuration and click "Create stack"
9. Monitor the "Events" tab for deployment progress

#### Option 2: AWS CLI
1. Open your terminal or command prompt
2. Run the following command:
   ```bash
   aws cloudformation create-stack \
     --stack-name ThreeTierArchitecture \
     --template-body file://three-tier-architecture.yaml \
     --parameters \
       ParameterKey=KeyName,ParameterValue=your-key-pair \
       ParameterKey=DBPassword,ParameterValue=your-secure-password \
     --capabilities CAPABILITY_IAM
   ```
3. Monitor stack creation:
   ```bash
   aws cloudformation describe-stacks --stack-name ThreeTierArchitecture
   ```

### Validating Your Template
Before deployment, validate your template with:
```bash
aws cloudformation validate-template --template-body file://three-tier-architecture.yaml
```

### Estimating Costs
To estimate deployment costs:
1. Navigate to CloudFormation in the AWS Console
2. Click "Create stack" and upload your template
3. Fill in parameters
4. On the "Review" page, click "Create change set"
5. Click "View cost estimate" to see the estimated monthly cost

## CloudFormation Best Practices

### Template Structure and Organization
- Use YAML format for better readability
- Include descriptive comments for complex sections
- Organize resources logically by tier or function
- Use the `Description` field to document template purpose
- Include `Metadata` section for template interface details

### Parameter Management
- Provide default values where appropriate
- Use parameter constraints (`AllowedValues`, `MinLength`, etc.)
- Include descriptions for all parameters
- Use parameter groups to organize related parameters
- Use `NoEcho: true` for sensitive parameters like passwords

### Security Considerations
- Follow the principle of least privilege for IAM roles
- Use `DeletionPolicy: Retain` for critical resources
- Avoid hardcoding sensitive information
- Use AWS Secrets Manager for database credentials in production
- Implement VPC endpoints for private communication

### Resource Management
- Use logical IDs that clearly indicate resource purpose
- Use `DependsOn` attribute to control creation order when needed
- Implement proper error handling with `CreationPolicy` and `UpdatePolicy`
- Use `Conditions` to create resources based on environment needs
- Leverage `Fn::GetAtt` instead of hardcoding resource attributes

### Reusability and Maintainability
- Use nested stacks for reusable components
- Implement cross-stack references for modular architectures
- Use mappings for environment-specific configurations
- Create reusable templates for common patterns
- Version control your templates with Git

### Testing and Deployment
- Test templates in a development environment first
- Use change sets to preview changes before applying
- Implement CI/CD pipelines for template deployment
- Consider using AWS CloudFormation Guard for policy compliance
- Use drift detection to identify manual changes

### Monitoring and Management
- Add appropriate tags to resources for cost tracking
- Create outputs for important resource information
- Set up CloudWatch alarms for stack events
- Implement stack policies to prevent accidental updates
- Use AWS CloudFormation StackSets for multi-account/region deployments

## Parameter Descriptions

### Basic Configuration

| Parameter | Description | Default Value | Required to Change? |
|-----------|-------------|---------------|---------------------|
| `EnvironmentName` | Prefix for all resource names | ThreeTierArch | Optional |
| `KeyName` | Name of an existing EC2 KeyPair for SSH access | None | **Required** |

### Network Configuration

| Parameter | Description | Default Value | Required to Change? |
|-----------|-------------|---------------|---------------------|
| `VpcCIDR` | CIDR block for the VPC | 192.168.0.0/16 | Optional |
| `PublicSubnetCIDR` | CIDR for the public subnet (Web & Bastion) | 192.168.1.0/24 | Optional |
| `PrivateSubnet1CIDR` | CIDR for the first private subnet (App Tier) | 192.168.2.0/24 | Optional |
| `PrivateSubnet2CIDR` | CIDR for the second private subnet (DB Tier) | 192.168.3.0/24 | Optional |
| `PrivateSubnet3CIDR` | CIDR for the third private subnet (DB Tier - Multi-AZ) | 192.168.4.0/24 | Optional |

### Instance Configuration

| Parameter | Description | Default Value | Required to Change? |
|-----------|-------------|---------------|---------------------|
| `BastionInstanceType` | EC2 instance type for Bastion Host | t2.micro | Optional |
| `WebServerInstanceType` | EC2 instance type for Web Server | t2.micro | Optional |
| `AppServerInstanceType` | EC2 instance type for App Server | t2.micro | Optional |
| `LatestAmiId` | AMI ID for Amazon Linux 2 | SSM Parameter | No (Auto-updated) |

### Database Configuration

| Parameter | Description | Default Value | Required to Change? |
|-----------|-------------|---------------|---------------------|
| `DBName` | Name of the database | mydb | Optional |
| `DBUsername` | Username for database access | root | Optional |
| `DBPassword` | Password for database access | None | **Required** |
| `DBInstanceClass` | RDS instance class | db.t2.micro | Optional |
| `DBAllocatedStorage` | Size of the database in GiB | 20 | Optional |
| `EnableMultiAZ` | Enable Multi-AZ deployment for RDS | false | Optional |

## Required Parameters

When deploying this CloudFormation template, you **must** provide values for:

1. **KeyName**: The name of an existing EC2 key pair that you have access to. This is required for SSH access to the instances.
   - Example: `my-key-pair`
   - Note: Make sure you have the private key (.pem file) stored securely on your local machine.

2. **DBPassword**: A secure password for the database.
   - Example: `MySecureP@ssw0rd`
   - Requirements: 
     - Minimum 8 characters
     - Maximum 41 characters
     - Alphanumeric characters only (a-z, A-Z, 0-9)

## Optional Parameters to Consider Changing

While not required, you might want to customize these parameters:

1. **EnvironmentName**: Change this to reflect your project or environment name.
   - Example: `ProductionThreeTier` or `DevThreeTier`

2. **DBName**: Change to a meaningful name for your application database.
   - Example: `customerdb` or `inventorydb`

3. **DBUsername**: Consider changing from the default `root` for better security.
   - Example: `dbadmin`

4. **EnableMultiAZ**: Set to `true` for production environments to improve availability.
   - Note: This will increase costs but provides better reliability.

## Deployment Instructions

To deploy this CloudFormation stack:

1. Navigate to the AWS CloudFormation console
2. Click "Create stack" > "With new resources (standard)"
3. Upload the template file `three-tier-architecture.yaml`
4. Fill in the required parameters (at minimum: KeyName and DBPassword)
5. Review and create the stack

## Post-Deployment

After successful deployment, check the Outputs tab in the CloudFormation console for:

- Web Server URL
- SSH command to connect to the Bastion Host
- Database endpoint for application configuration

To connect to the App Server (in the private subnet):
1. SSH into the Bastion Host using the provided SSH command
2. From the Bastion Host, SSH to the App Server using its private IP:
   ```
   ssh -i ~/.ssh/key-pair.pem ec2-user@<AppServerPrivateIP>
   ```

## Security Considerations

- The template creates security groups with necessary permissions for the three-tier architecture
- For production use, consider restricting SSH access to specific IP ranges rather than 0.0.0.0/0
- Consider enabling encryption for the RDS instance in production environments
- Review and adjust security group rules based on your specific requirements
