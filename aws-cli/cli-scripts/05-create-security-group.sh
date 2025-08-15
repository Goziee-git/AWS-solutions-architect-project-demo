#!/bin/bash

# Script: 05-create-security-group.sh
# Purpose: Create security group with SSH and HTTP access rules
# Usage: ./05-create-security-group.sh

# Source variables
source "$(dirname "$0")/variables.sh"

log_info "Starting Security Group creation..."

# Check prerequisites
if [ -z "$VPC_ID" ]; then
    log_error "VPC_ID is not set. Please run 01-create-vpc.sh first."
    exit 1
fi

# Create Security Group
log_info "Creating security group in VPC $VPC_ID..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name "${PROJECT_NAME}-sg" \
    --description "Security group for ${PROJECT_NAME} EC2 instances" \
    --vpc-id $VPC_ID \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=security-group,Tags=[{$TAG_PROJECT},{$TAG_ENVIRONMENT},{$TAG_OWNER},{Key=Name,Value=${PROJECT_NAME}-sg}]" \
    --query 'GroupId' \
    --output text)

if [ $? -eq 0 ] && [ "$SECURITY_GROUP_ID" != "None" ]; then
    log_success "Security group created: $SECURITY_GROUP_ID"
    
    # Update variables file
    sed -i "s/^export SECURITY_GROUP_ID=.*/export SECURITY_GROUP_ID=\"$SECURITY_GROUP_ID\"/" "$(dirname "$0")/variables.sh"
else
    log_error "Failed to create security group"
    exit 1
fi

# Add SSH access rule (port 22)
log_info "Adding SSH access rule (port 22 from anywhere)..."
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "SSH access rule added (port 22)"
else
    log_error "Failed to add SSH access rule"
fi

# Add HTTP access rule (port 80)
log_info "Adding HTTP access rule (port 80 from anywhere)..."
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "HTTP access rule added (port 80)"
else
    log_error "Failed to add HTTP access rule"
fi

# Add HTTPS access rule (port 443)
log_info "Adding HTTPS access rule (port 443 from anywhere)..."
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "HTTPS access rule added (port 443)"
else
    log_error "Failed to add HTTPS access rule"
fi

# Add ICMP rule for ping
log_info "Adding ICMP rule for ping..."
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol icmp \
    --port -1 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "ICMP rule added (ping)"
else
    log_error "Failed to add ICMP rule"
fi

# Wait a moment for rules to be applied
sleep 2

# Display security group information
log_info "Security Group Details:"
aws ec2 describe-security-groups \
    --group-ids $SECURITY_GROUP_ID \
    --region $AWS_REGION \
    --query 'SecurityGroups[0].{GroupId:GroupId,GroupName:GroupName,Description:Description,VpcId:VpcId}' \
    --output table

log_info "Inbound Rules:"
aws ec2 describe-security-groups \
    --group-ids $SECURITY_GROUP_ID \
    --region $AWS_REGION \
    --query 'SecurityGroups[0].IpPermissions[*].{Protocol:IpProtocol,Port:FromPort,Source:IpRanges[0].CidrIp}' \
    --output table

log_info "Outbound Rules:"
aws ec2 describe-security-groups \
    --group-ids $SECURITY_GROUP_ID \
    --region $AWS_REGION \
    --query 'SecurityGroups[0].IpPermissionsEgress[*].{Protocol:IpProtocol,Port:FromPort,Destination:IpRanges[0].CidrIp}' \
    --output table

# Security recommendations
log_info "Security Recommendations:"
echo -e "${YELLOW}⚠️  Current configuration allows SSH access from anywhere (0.0.0.0/0)${NC}"
echo -e "${YELLOW}⚠️  For production, consider restricting SSH access to your IP only${NC}"
echo -e "${BLUE}💡 To restrict SSH to your current IP, run:${NC}"
echo -e "${BLUE}   MY_IP=\$(curl -s https://checkip.amazonaws.com)${NC}"
echo -e "${BLUE}   aws ec2 revoke-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0${NC}"
echo -e "${BLUE}   aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr \${MY_IP}/32${NC}"

log_success "Security Group creation completed successfully!"
log_info "Security Group ID: $SECURITY_GROUP_ID"
log_info "Next step: Run ./06-create-ami.sh"
