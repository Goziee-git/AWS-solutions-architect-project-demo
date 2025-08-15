#!/bin/bash

# AWS Infrastructure Configuration Variables
# Source this file before running other scripts: source variables.sh

# Project Configuration
export PROJECT_NAME="aws-simple-architecture"
export ENVIRONMENT="dev"

# AWS Region (change as needed)
export AWS_REGION="us-east-1"
export AVAILABILITY_ZONE="${AWS_REGION}a"

# VPC Configuration
export VPC_CIDR="10.0.0.0/16"
export PUBLIC_SUBNET_CIDR="10.0.1.0/24"
export PRIVATE_SUBNET_CIDR="10.0.2.0/24"

# EC2 Configuration
export INSTANCE_TYPE="t2.micro"
export KEY_PAIR_NAME="my-key-pair"  # Change this to your key pair name

# AMI Configuration (Amazon Linux 2 - will be updated dynamically)
export BASE_AMI_ID="ami-0c02fb55956c7d316"  # Amazon Linux 2 in us-east-1

# Tags
export TAG_PROJECT="Key=Project,Value=${PROJECT_NAME}"
export TAG_ENVIRONMENT="Key=Environment,Value=${ENVIRONMENT}"
export TAG_OWNER="Key=Owner,Value=$(whoami)"

# Resource IDs (will be populated by scripts)
export VPC_ID=""
export PUBLIC_SUBNET_ID=""
export PRIVATE_SUBNET_ID=""
export IGW_ID=""
export ROUTE_TABLE_ID=""
export SECURITY_GROUP_ID=""
export AMI_ID=""
export INSTANCE_ID=""
export SNAPSHOT_ID=""

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured or credentials are invalid."
        log_info "Run 'aws configure' to set up your credentials."
        exit 1
    fi
    
    log_success "AWS CLI is properly configured"
}

# Get the latest Amazon Linux 2 AMI ID
get_latest_ami() {
    log_info "Getting latest Amazon Linux 2 AMI ID..."
    BASE_AMI_ID=$(aws ec2 describe-images \
        --owners amazon \
        --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text \
        --region $AWS_REGION)
    
    if [ "$BASE_AMI_ID" != "None" ] && [ -n "$BASE_AMI_ID" ]; then
        log_success "Latest AMI ID: $BASE_AMI_ID"
        export BASE_AMI_ID
    else
        log_error "Failed to get latest AMI ID"
        exit 1
    fi
}

# Verify key pair exists
check_key_pair() {
    log_info "Checking if key pair '$KEY_PAIR_NAME' exists..."
    if aws ec2 describe-key-pairs --key-names "$KEY_PAIR_NAME" --region $AWS_REGION &> /dev/null; then
        log_success "Key pair '$KEY_PAIR_NAME' exists"
    else
        log_error "Key pair '$KEY_PAIR_NAME' does not exist"
        log_info "Create it with: aws ec2 create-key-pair --key-name $KEY_PAIR_NAME --query 'KeyMaterial' --output text > ${KEY_PAIR_NAME}.pem"
        log_info "Then set permissions: chmod 400 ${KEY_PAIR_NAME}.pem"
        exit 1
    fi
}

# Initialize - run checks when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    log_info "Initializing AWS infrastructure variables..."
    check_aws_cli
    get_latest_ami
    check_key_pair
    log_success "Variables initialized successfully"
else
    # Script is being sourced
    log_info "Variables loaded. Run individual scripts or use check functions as needed."
fi

# Display current configuration
show_config() {
    echo -e "\n${BLUE}=== Current Configuration ===${NC}"
    echo "Project Name: $PROJECT_NAME"
    echo "Environment: $ENVIRONMENT"
    echo "AWS Region: $AWS_REGION"
    echo "Availability Zone: $AVAILABILITY_ZONE"
    echo "VPC CIDR: $VPC_CIDR"
    echo "Public Subnet CIDR: $PUBLIC_SUBNET_CIDR"
    echo "Private Subnet CIDR: $PRIVATE_SUBNET_CIDR"
    echo "Instance Type: $INSTANCE_TYPE"
    echo "Key Pair: $KEY_PAIR_NAME"
    echo "Base AMI ID: $BASE_AMI_ID"
    echo -e "${BLUE}================================${NC}\n"
}
