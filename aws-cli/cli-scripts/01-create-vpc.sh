#!/bin/bash

# Script: 01-create-vpc.sh
# Purpose: Create a custom VPC with DNS support
# Usage: ./01-create-vpc.sh

# Source variables
source "$(dirname "$0")/variables.sh"

log_info "Starting VPC creation..."

# Check if VPC already exists
if [ -n "$VPC_ID" ] && aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region $AWS_REGION &> /dev/null; then
    log_warning "VPC $VPC_ID already exists"
    exit 0
fi

# Create VPC
log_info "Creating VPC with CIDR block $VPC_CIDR..."
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=vpc,Tags=[{$TAG_PROJECT},{$TAG_ENVIRONMENT},{$TAG_OWNER},{Key=Name,Value=${PROJECT_NAME}-vpc}]" \
    --query 'Vpc.VpcId' \
    --output text)

if [ $? -eq 0 ] && [ "$VPC_ID" != "None" ]; then
    log_success "VPC created successfully: $VPC_ID"
    
    # Update variables file with VPC ID
    sed -i "s/^export VPC_ID=.*/export VPC_ID=\"$VPC_ID\"/" "$(dirname "$0")/variables.sh"
    
    # Wait for VPC to be available
    log_info "Waiting for VPC to become available..."
    aws ec2 wait vpc-available --vpc-ids $VPC_ID --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        log_success "VPC is now available"
    else
        log_error "Timeout waiting for VPC to become available"
        exit 1
    fi
else
    log_error "Failed to create VPC"
    exit 1
fi

# Enable DNS hostnames and DNS resolution
log_info "Enabling DNS hostnames for VPC..."
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "DNS hostnames enabled"
else
    log_error "Failed to enable DNS hostnames"
fi

log_info "Enabling DNS resolution for VPC..."
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-support \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "DNS resolution enabled"
else
    log_error "Failed to enable DNS resolution"
fi

# Display VPC information
log_info "VPC Details:"
aws ec2 describe-vpcs \
    --vpc-ids $VPC_ID \
    --region $AWS_REGION \
    --query 'Vpcs[0].{VpcId:VpcId,CidrBlock:CidrBlock,State:State,DnsHostnames:EnableDnsHostnames,DnsResolution:EnableDnsSupport}' \
    --output table

log_success "VPC creation completed successfully!"
log_info "VPC ID: $VPC_ID"
log_info "Next step: Run ./02-create-subnets.sh"
