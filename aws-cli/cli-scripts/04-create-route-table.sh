#!/bin/bash

# Script: 04-create-route-table.sh
# Purpose: Create route table and configure routing for public subnet
# Usage: ./04-create-route-table.sh

# Source variables
source "$(dirname "$0")/variables.sh"

log_info "Starting Route Table creation and configuration..."

# Check prerequisites
if [ -z "$VPC_ID" ]; then
    log_error "VPC_ID is not set. Please run 01-create-vpc.sh first."
    exit 1
fi

if [ -z "$PUBLIC_SUBNET_ID" ]; then
    log_error "PUBLIC_SUBNET_ID is not set. Please run 02-create-subnets.sh first."
    exit 1
fi

if [ -z "$IGW_ID" ]; then
    log_error "IGW_ID is not set. Please run 03-create-igw.sh first."
    exit 1
fi

# Create Route Table
log_info "Creating route table for public subnet..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=route-table,Tags=[{$TAG_PROJECT},{$TAG_ENVIRONMENT},{$TAG_OWNER},{Key=Name,Value=${PROJECT_NAME}-public-rt},{Key=Type,Value=Public}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

if [ $? -eq 0 ] && [ "$ROUTE_TABLE_ID" != "None" ]; then
    log_success "Route table created: $ROUTE_TABLE_ID"
    
    # Update variables file
    sed -i "s/^export ROUTE_TABLE_ID=.*/export ROUTE_TABLE_ID=\"$ROUTE_TABLE_ID\"/" "$(dirname "$0")/variables.sh"
else
    log_error "Failed to create route table"
    exit 1
fi

# Add route to Internet Gateway (0.0.0.0/0 -> IGW)
log_info "Adding route to Internet Gateway (0.0.0.0/0 -> $IGW_ID)..."
aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "Route to Internet Gateway added successfully"
else
    log_error "Failed to add route to Internet Gateway"
    exit 1
fi

# Associate route table with public subnet
log_info "Associating route table with public subnet..."
ASSOCIATION_ID=$(aws ec2 associate-route-table \
    --route-table-id $ROUTE_TABLE_ID \
    --subnet-id $PUBLIC_SUBNET_ID \
    --region $AWS_REGION \
    --query 'AssociationId' \
    --output text)

if [ $? -eq 0 ] && [ "$ASSOCIATION_ID" != "None" ]; then
    log_success "Route table associated with public subnet: $ASSOCIATION_ID"
else
    log_error "Failed to associate route table with public subnet"
    exit 1
fi

# Wait a moment for changes to propagate
sleep 2

# Display route table information
log_info "Route Table Details:"
aws ec2 describe-route-tables \
    --route-table-ids $ROUTE_TABLE_ID \
    --region $AWS_REGION \
    --query 'RouteTables[0].{RouteTableId:RouteTableId,VpcId:VpcId,Routes:Routes[*].{Destination:DestinationCidrBlock,Target:GatewayId,State:State}}' \
    --output table

log_info "Route Table Associations:"
aws ec2 describe-route-tables \
    --route-table-ids $ROUTE_TABLE_ID \
    --region $AWS_REGION \
    --query 'RouteTables[0].Associations[*].{AssociationId:RouteTableAssociationId,SubnetId:SubnetId,Main:Main}' \
    --output table

# Verify connectivity setup
log_info "Verifying public subnet routing configuration..."

# Check if public subnet has internet route
INTERNET_ROUTE=$(aws ec2 describe-route-tables \
    --filters "Name=association.subnet-id,Values=$PUBLIC_SUBNET_ID" \
    --region $AWS_REGION \
    --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0`].GatewayId' \
    --output text)

if [ "$INTERNET_ROUTE" = "$IGW_ID" ]; then
    log_success "Public subnet is properly configured for internet access"
else
    log_warning "Public subnet may not have proper internet routing"
fi

log_success "Route Table creation and configuration completed successfully!"
log_info "Route Table ID: $ROUTE_TABLE_ID"
log_info "Association ID: $ASSOCIATION_ID"
log_info "Next step: Run ./05-create-security-group.sh"
