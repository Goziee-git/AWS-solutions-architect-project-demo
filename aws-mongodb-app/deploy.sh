#!/bin/bash

# AWS MongoDB Application Deployment Script
# This script automates the deployment of the MongoDB application on AWS

set -e

# Configuration
ENVIRONMENT_NAME="mongodb-app"
KEY_PAIR_NAME="mongodb-app-key"
INSTANCE_TYPE="t3.medium"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is configured
check_aws_cli() {
    print_status "Checking AWS CLI configuration..."
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_status "AWS CLI is configured."
}

# Function to create key pair if it doesn't exist
create_key_pair() {
    print_status "Checking for EC2 key pair..."
    if aws ec2 describe-key-pairs --key-names $KEY_PAIR_NAME > /dev/null 2>&1; then
        print_warning "Key pair $KEY_PAIR_NAME already exists."
    else
        print_status "Creating EC2 key pair..."
        aws ec2 create-key-pair --key-name $KEY_PAIR_NAME --query 'KeyMaterial' --output text > ${KEY_PAIR_NAME}.pem
        chmod 400 ${KEY_PAIR_NAME}.pem
        print_status "Key pair created and saved as ${KEY_PAIR_NAME}.pem"
    fi
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure stack..."
    
    aws cloudformation create-stack \
        --stack-name ${ENVIRONMENT_NAME}-infrastructure \
        --template-body file://aws/cloudformation.yaml \
        --parameters ParameterKey=EnvironmentName,ParameterValue=$ENVIRONMENT_NAME \
                     ParameterKey=KeyPairName,ParameterValue=$KEY_PAIR_NAME \
        --capabilities CAPABILITY_IAM \
        --region $REGION
    
    print_status "Waiting for infrastructure stack to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name ${ENVIRONMENT_NAME}-infrastructure \
        --region $REGION
    
    print_status "Infrastructure stack deployed successfully."
}

# Function to deploy EC2 instances
deploy_instances() {
    print_status "Deploying EC2 instances stack..."
    
    aws cloudformation create-stack \
        --stack-name ${ENVIRONMENT_NAME}-instances \
        --template-body file://aws/ec2-instances.yaml \
        --parameters ParameterKey=EnvironmentName,ParameterValue=$ENVIRONMENT_NAME \
                     ParameterKey=KeyPairName,ParameterValue=$KEY_PAIR_NAME \
                     ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE \
        --capabilities CAPABILITY_IAM \
        --region $REGION
    
    print_status "Waiting for instances stack to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name ${ENVIRONMENT_NAME}-instances \
        --region $REGION
    
    print_status "EC2 instances stack deployed successfully."
}

# Function to get deployment outputs
get_outputs() {
    print_status "Getting deployment outputs..."
    
    # Get Load Balancer URL
    ALB_URL=$(aws cloudformation describe-stacks \
        --stack-name ${ENVIRONMENT_NAME}-infrastructure \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
        --output text \
        --region $REGION)
    
    # Get Bastion Host IP
    BASTION_IP=$(aws cloudformation describe-stacks \
        --stack-name ${ENVIRONMENT_NAME}-instances \
        --query 'Stacks[0].Outputs[?OutputKey==`BastionHostIP`].OutputValue' \
        --output text \
        --region $REGION)
    
    echo ""
    echo "=========================================="
    echo "DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "=========================================="
    echo "Application URL: $ALB_URL"
    echo "Bastion Host IP: $BASTION_IP"
    echo "SSH Key: ${KEY_PAIR_NAME}.pem"
    echo ""
    echo "Next Steps:"
    echo "1. SSH to bastion host: ssh -i ${KEY_PAIR_NAME}.pem ec2-user@$BASTION_IP"
    echo "2. Deploy application code to each instance"
    echo "3. Configure MongoDB replication"
    echo "4. Test the application at: $ALB_URL"
    echo "=========================================="
}

# Function to clean up resources
cleanup() {
    print_warning "Cleaning up AWS resources..."
    
    print_status "Deleting instances stack..."
    aws cloudformation delete-stack --stack-name ${ENVIRONMENT_NAME}-instances --region $REGION
    aws cloudformation wait stack-delete-complete --stack-name ${ENVIRONMENT_NAME}-instances --region $REGION
    
    print_status "Deleting infrastructure stack..."
    aws cloudformation delete-stack --stack-name ${ENVIRONMENT_NAME}-infrastructure --region $REGION
    aws cloudformation wait stack-delete-complete --stack-name ${ENVIRONMENT_NAME}-infrastructure --region $REGION
    
    print_status "Cleanup completed."
}

# Main deployment function
deploy() {
    print_status "Starting AWS MongoDB Application deployment..."
    
    check_aws_cli
    create_key_pair
    deploy_infrastructure
    deploy_instances
    get_outputs
}

# Function to show help
show_help() {
    echo "AWS MongoDB Application Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy    Deploy the complete application infrastructure"
    echo "  cleanup   Remove all AWS resources"
    echo "  help      Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ENVIRONMENT_NAME  Environment name prefix (default: mongodb-app)"
    echo "  KEY_PAIR_NAME     EC2 key pair name (default: mongodb-app-key)"
    echo "  INSTANCE_TYPE     EC2 instance type (default: t3.medium)"
    echo "  REGION           AWS region (default: us-east-1)"
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    cleanup)
        cleanup
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
