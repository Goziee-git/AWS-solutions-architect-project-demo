#!/bin/bash

# Script: 02-create-subnets.sh
# Purpose: Create public and private subnets in the VPC
# Usage: ./02-create-subnets.sh

# Source variables
source "$(dirname "$0")/variables.sh"

log_info "Starting subnet creation..."

# Check if VPC exists
if [ -z "$VPC_ID" ]; then
    log_error "VPC_ID is not set. Please run 01-create-vpc.sh first."
    exit 1
fi

# Verify VPC exists
#if ! aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region $AWS_REGION &> /dev/null; then
 
#    log_error "VPC $VPC_ID does not exist"
#    exit 1
#fi

# Create Public Subnet
log_info "Creating public subnet with CIDR $PUBLIC_SUBNET_CIDR in AZ $AVAILABILITY_ZONE..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET_CIDR \
    --availability-zone $AVAILABILITY_ZONE \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=subnet,Tags=[{$TAG_PROJECT},{$TAG_ENVIRONMENT},{$TAG_OWNER},{Key=Name,Value=${PROJECT_NAME}-public-subnet},{Key=Type,Value=Public}]" \
    --query 'Subnet.SubnetId' \
    --output text)

if [ $? -eq 0 ] && [ "$PUBLIC_SUBNET_ID" != "None" ]; then
    log_success "Public subnet created: $PUBLIC_SUBNET_ID"
    
    # Update variables file
    sed -i "s/^export PUBLIC_SUBNET_ID=.*/export PUBLIC_SUBNET_ID=\"$PUBLIC_SUBNET_ID\"/" "$(dirname "$0")/variables.sh"
    
    # Enable auto-assign public IP for public subnet
    log_info "Enabling auto-assign public IP for public subnet..."
    aws ec2 modify-subnet-attribute \
        --subnet-id $PUBLIC_SUBNET_ID \
        --map-public-ip-on-launch \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        log_success "Auto-assign public IP enabled for public subnet"
    else
        log_error "Failed to enable auto-assign public IP"
    fi
else
    log_error "Failed to create public subnet"
    exit 1
fi

# Create Private Subnet
log_info "Creating private subnet with CIDR $PRIVATE_SUBNET_CIDR in AZ $AVAILABILITY_ZONE..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PRIVATE_SUBNET_CIDR \
    --availability-zone $AVAILABILITY_ZONE \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=subnet,Tags=[{$TAG_PROJECT},{$TAG_ENVIRONMENT},{$TAG_OWNER},{Key=Name,Value=${PROJECT_NAME}-private-subnet},{Key=Type,Value=Private}]" \
    --query 'Subnet.SubnetId' \
    --output text)

if [ $? -eq 0 ] && [ "$PRIVATE_SUBNET_ID" != "None" ]; then
    log_success "Private subnet created: $PRIVATE_SUBNET_ID"
    
    # Update variables file
    sed -i "s/^export PRIVATE_SUBNET_ID=.*/export PRIVATE_SUBNET_ID=\"$PRIVATE_SUBNET_ID\"/" "$(dirname "$0")/variables.sh"
else
    log_error "Failed to create private subnet"
    exit 1
fi

# Wait for subnets to be available
log_info "Waiting for subnets to become available..."
aws ec2 wait subnet-available --subnet-ids $PUBLIC_SUBNET_ID $PRIVATE_SUBNET_ID --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "Subnets are now available"
else
    log_error "Timeout waiting for subnets to become available"
fi

# Display subnet information
log_info "Subnet Details:"
aws ec2 describe-subnets \
    --subnet-ids $PUBLIC_SUBNET_ID $PRIVATE_SUBNET_ID \
    --region $AWS_REGION \
    --query 'Subnets[*].{SubnetId:SubnetId,CidrBlock:CidrBlock,AvailabilityZone:AvailabilityZone,State:State,Type:Tags[?Key==`Type`].Value|[0],MapPublicIp:MapPublicIpOnLaunch}' \
    --output table

log_success "Subnet creation completed successfully!"
log_info "Public Subnet ID: $PUBLIC_SUBNET_ID"
log_info "Private Subnet ID: $PRIVATE_SUBNET_ID"
log_info "Next step: Run ./03-create-igw.sh"
