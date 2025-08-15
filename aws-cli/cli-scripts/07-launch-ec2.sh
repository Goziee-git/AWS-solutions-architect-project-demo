#!/bin/bash

# Script: 07-launch-ec2.sh
# Purpose: Launch EC2 instance using the custom AMI
# Usage: ./07-launch-ec2.sh

# Source variables
source "$(dirname "$0")/variables.sh"

log_info "Starting EC2 instance launch..."

# Check prerequisites
if [ -z "$VPC_ID" ] || [ -z "$PUBLIC_SUBNET_ID" ] || [ -z "$SECURITY_GROUP_ID" ] || [ -z "$AMI_ID" ]; then
    log_error "Missing prerequisites. Please run previous scripts first."
    log_info "Required: VPC_ID, PUBLIC_SUBNET_ID, SECURITY_GROUP_ID, AMI_ID"
    exit 1
fi

# Verify AMI exists and is available
log_info "Verifying AMI availability..."
AMI_STATE=$(aws ec2 describe-images \
    --image-ids $AMI_ID \
    --region $AWS_REGION \
    --query 'Images[0].State' \
    --output text)

if [ "$AMI_STATE" != "available" ]; then
    log_error "AMI $AMI_ID is not available (current state: $AMI_STATE)"
    log_info "Please wait for AMI to become available or run 06-create-ami.sh"
    exit 1
fi

log_success "AMI $AMI_ID is available"

# Launch EC2 instance
log_info "Launching EC2 instance with custom AMI..."
log_info "Instance type: $INSTANCE_TYPE"
log_info "Key pair: $KEY_PAIR_NAME"
log_info "Subnet: $PUBLIC_SUBNET_ID (public)"
log_info "Security group: $SECURITY_GROUP_ID"

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_PAIR_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --subnet-id $PUBLIC_SUBNET_ID \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=instance,Tags=[{$TAG_PROJECT},{$TAG_ENVIRONMENT},{$TAG_OWNER},{Key=Name,Value=${PROJECT_NAME}-web-server}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ $? -eq 0 ] && [ "$INSTANCE_ID" != "None" ]; then
    log_success "EC2 instance launched: $INSTANCE_ID"
    
    # Update variables file
    sed -i "s/^export INSTANCE_ID=.*/export INSTANCE_ID=\"$INSTANCE_ID\"/" "$(dirname "$0")/variables.sh"
else
    log_error "Failed to launch EC2 instance"
    exit 1
fi

# Wait for instance to be running
log_info "Waiting for instance to be in running state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "Instance is now running"
else
    log_error "Timeout waiting for instance to run"
    exit 1
fi

# Wait for status checks to pass
log_info "Waiting for status checks to pass..."
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "Instance status checks passed"
else
    log_warning "Status checks may still be in progress"
fi

# Get instance details
log_info "Retrieving instance details..."
INSTANCE_DETAILS=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].{InstanceId:InstanceId,State:State.Name,InstanceType:InstanceType,PublicIp:PublicIpAddress,PrivateIp:PrivateIpAddress,SubnetId:SubnetId,VpcId:VpcId}')

echo "$INSTANCE_DETAILS" | jq -r '
"Instance Details:
  Instance ID: " + .InstanceId + "
  State: " + .State + "
  Type: " + .InstanceType + "
  Public IP: " + (.PublicIp // "N/A") + "
  Private IP: " + (.PrivateIp // "N/A") + "
  Subnet ID: " + .SubnetId + "
  VPC ID: " + .VpcId'

# Extract public IP for further use
PUBLIC_IP=$(echo "$INSTANCE_DETAILS" | jq -r '.PublicIp // empty')

if [ -n "$PUBLIC_IP" ]; then
    log_success "Instance has public IP: $PUBLIC_IP"
    
    # Test web server connectivity
    log_info "Testing web server connectivity..."
    sleep 30  # Give the web server time to start
    
    for i in {1..6}; do
        if curl -s --connect-timeout 10 "http://$PUBLIC_IP" > /dev/null; then
            log_success "Web server is responding!"
            log_info "🌐 Access your web server at: http://$PUBLIC_IP"
            break
        else
            log_info "Attempt $i/6: Web server not ready yet, waiting..."
            sleep 10
        fi
    done
    
    # SSH connection information
    log_info "SSH Connection:"
    echo -e "${BLUE}ssh -i ~/.ssh/${KEY_PAIR_NAME}.pem ec2-user@${PUBLIC_IP}${NC}"
    
else
    log_warning "Instance does not have a public IP address"
fi

# Display comprehensive instance information
log_info "Complete Instance Information:"
aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].{InstanceId:InstanceId,ImageId:ImageId,State:State.Name,InstanceType:InstanceType,KeyName:KeyName,LaunchTime:LaunchTime,PublicIpAddress:PublicIpAddress,PrivateIpAddress:PrivateIpAddress,SubnetId:SubnetId,VpcId:VpcId,SecurityGroups:SecurityGroups[0].GroupId}' \
    --output table

# Display security group information
log_info "Security Group Rules:"
aws ec2 describe-security-groups \
    --group-ids $SECURITY_GROUP_ID \
    --region $AWS_REGION \
    --query 'SecurityGroups[0].IpPermissions[*].{Protocol:IpProtocol,Port:FromPort,Source:IpRanges[0].CidrIp}' \
    --output table

# Cost estimation
log_info "💰 Cost Estimation (approximate):"
echo -e "${YELLOW}Instance Type: $INSTANCE_TYPE${NC}"
echo -e "${YELLOW}Estimated cost: ~$0.0116/hour (~$8.50/month)${NC}"
echo -e "${YELLOW}Free tier: 750 hours/month for first 12 months${NC}"

# Next steps and recommendations
log_success "🎉 EC2 instance deployment completed successfully!"
echo -e "\n${GREEN}=== Deployment Summary ===${NC}"
echo -e "✅ VPC created with custom CIDR: $VPC_CIDR"
echo -e "✅ Public subnet: $PUBLIC_SUBNET_CIDR"
echo -e "✅ Private subnet: $PRIVATE_SUBNET_CIDR"
echo -e "✅ Internet Gateway attached"
echo -e "✅ Route table configured"
echo -e "✅ Security group with HTTP/SSH access"
echo -e "✅ Custom AMI with Apache web server"
echo -e "✅ EC2 instance running: $INSTANCE_ID"

if [ -n "$PUBLIC_IP" ]; then
    echo -e "\n${BLUE}=== Access Information ===${NC}"
    echo -e "🌐 Web Server: http://$PUBLIC_IP"
    echo -e "🔐 SSH Access: ssh -i ~/.ssh/${KEY_PAIR_NAME}.pem ec2-user@${PUBLIC_IP}"
fi

echo -e "\n${YELLOW}=== Next Steps ===${NC}"
echo -e "1. Test the web application in your browser"
echo -e "2. Connect via SSH to explore the instance"
echo -e "3. Monitor costs in AWS Billing Dashboard"
echo -e "4. Run ./cleanup.sh when you're done to avoid charges"

echo -e "\n${YELLOW}=== Troubleshooting ===${NC}"
echo -e "• If web server doesn't respond, check security group rules"
echo -e "• If SSH fails, verify key pair and security group"
echo -e "• Check instance logs: aws ec2 get-console-output --instance-id $INSTANCE_ID"

log_info "Deployment completed! 🚀"
