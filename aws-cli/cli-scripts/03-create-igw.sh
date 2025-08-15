#!/bin/bash

# Script: 03-create-igw.sh
# Purpose: Create and attach Internet Gateway to VPC
# Usage: ./03-create-igw.sh

# Source variables
source "$(dirname "$0")/variables.sh"

log_info "Starting Internet Gateway creation..."

# Check if VPC exists
if [ -z "$VPC_ID" ]; then
    log_error "VPC_ID is not set. Please run 01-create-vpc.sh first."
    exit 1
fi

# Verify VPC exists
if ! aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region $AWS_REGION &> /dev/null; then
    log_error "VPC $VPC_ID does not exist"
    exit 1
fi

# Create Internet Gateway
log_info "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{$TAG_PROJECT},{$TAG_ENVIRONMENT},{$TAG_OWNER},{Key=Name,Value=${PROJECT_NAME}-igw}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

if [ $? -eq 0 ] && [ "$IGW_ID" != "None" ]; then
    log_success "Internet Gateway created: $IGW_ID"
    
    # Update variables file
    sed -i "s/^export IGW_ID=.*/export IGW_ID=\"$IGW_ID\"/" "$(dirname "$0")/variables.sh"
else
    log_error "Failed to create Internet Gateway"
    exit 1
fi

# Attach Internet Gateway to VPC
log_info "Attaching Internet Gateway to VPC..."
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "Internet Gateway attached to VPC successfully"
else
    log_error "Failed to attach Internet Gateway to VPC"
    exit 1
fi

# Wait a moment for attachment to complete
sleep 2

# Verify attachment
log_info "Verifying Internet Gateway attachment..."
ATTACHMENT_STATE=$(aws ec2 describe-internet-gateways \
    --internet-gateway-ids $IGW_ID \
    --region $AWS_REGION \
    --query 'InternetGateways[0].Attachments[0].State' \
    --output text)

if [ "$ATTACHMENT_STATE" = "available" ]; then
    log_success "Internet Gateway is properly attached and available"
else
    log_warning "Internet Gateway attachment state: $ATTACHMENT_STATE"
fi

# Display Internet Gateway information
log_info "Internet Gateway Details:"
aws ec2 describe-internet-gateways \
    --internet-gateway-ids $IGW_ID \
    --region $AWS_REGION \
    --query 'InternetGateways[0].{InternetGatewayId:InternetGatewayId,State:Attachments[0].State,VpcId:Attachments[0].VpcId}' \
    --output table

log_success "Internet Gateway creation and attachment completed successfully!"
log_info "Internet Gateway ID: $IGW_ID"
log_info "Next step: Run ./04-create-route-table.sh"
