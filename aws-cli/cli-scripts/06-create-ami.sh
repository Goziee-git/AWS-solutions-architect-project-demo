#!/bin/bash

# Script: 06-create-ami.sh
# Purpose: Create a custom AMI with pre-installed software
# Usage: ./06-create-ami.sh

# Source variables
source "$(dirname "$0")/variables.sh"

log_info "Starting custom AMI creation process..."

# Check prerequisites
if [ -z "$VPC_ID" ] || [ -z "$PUBLIC_SUBNET_ID" ] || [ -z "$SECURITY_GROUP_ID" ]; then
    log_error "Missing prerequisites. Please run previous scripts first."
    exit 1
fi

# User data script for instance configuration
USER_DATA_SCRIPT=$(cat << 'EOF'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create a simple web page
cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>AWS Simple Architecture Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
        .container { background-color: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { color: #232F3E; border-bottom: 2px solid #FF9900; padding-bottom: 10px; }
        .info { margin: 20px 0; }
        .highlight { background-color: #FF9900; color: white; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🚀 AWS Simple Architecture Demo</h1>
        <div class="info">
            <h2>Instance Information</h2>
            <p><strong>Instance ID:</strong> <span class="highlight">$(curl -s http://169.254.169.254/latest/meta-data/instance-id)</span></p>
            <p><strong>Availability Zone:</strong> <span class="highlight">$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</span></p>
            <p><strong>Instance Type:</strong> <span class="highlight">$(curl -s http://169.254.169.254/latest/meta-data/instance-type)</span></p>
            <p><strong>Public IP:</strong> <span class="highlight">$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</span></p>
            <p><strong>Private IP:</strong> <span class="highlight">$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</span></p>
        </div>
        <div class="info">
            <h2>Architecture Components</h2>
            <ul>
                <li>✅ Custom VPC with DNS support</li>
                <li>✅ Public and Private Subnets</li>
                <li>✅ Internet Gateway for connectivity</li>
                <li>✅ Route Table configuration</li>
                <li>✅ Security Group with HTTP/SSH access</li>
                <li>✅ Custom AMI with Apache web server</li>
                <li>✅ EC2 instance in public subnet</li>
            </ul>
        </div>
        <div class="info">
            <p><em>This page is served by Apache HTTP Server running on Amazon Linux 2</em></p>
            <p><em>Created: $(date)</em></p>
        </div>
    </div>
</body>
</html>
HTML

# Create system info script
cat > /usr/local/bin/system-info.sh << 'SCRIPT'
#!/bin/bash
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"
echo "Disk Usage: $(df -h / | tail -1)"
echo "Memory Usage: $(free -h | grep Mem)"
echo "Network Interfaces: $(ip addr show | grep inet | grep -v 127.0.0.1)"
SCRIPT

chmod +x /usr/local/bin/system-info.sh

# Signal completion
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource LaunchConfig --region ${AWS::Region} 2>/dev/null || echo "AMI setup completed"
EOF
)

# Encode user data in base64
USER_DATA_B64=$(echo "$USER_DATA_SCRIPT" | base64 -w 0)

# Launch temporary instance for AMI creation
log_info "Launching temporary instance for AMI creation..."
log_info "Using base AMI: $BASE_AMI_ID"

TEMP_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $BASE_AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_PAIR_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --subnet-id $PUBLIC_SUBNET_ID \
    --user-data "$USER_DATA_B64" \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=instance,Tags=[{$TAG_PROJECT},{$TAG_ENVIRONMENT},{$TAG_OWNER},{Key=Name,Value=${PROJECT_NAME}-temp-for-ami},{Key=Purpose,Value=AMI-Creation}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ $? -eq 0 ] && [ "$TEMP_INSTANCE_ID" != "None" ]; then
    log_success "Temporary instance launched: $TEMP_INSTANCE_ID"
else
    log_error "Failed to launch temporary instance"
    exit 1
fi

# Wait for instance to be running
log_info "Waiting for instance to be in running state..."
aws ec2 wait instance-running --instance-ids $TEMP_INSTANCE_ID --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "Instance is now running"
else
    log_error "Timeout waiting for instance to run"
    exit 1
fi

# Wait additional time for user data script to complete
log_info "Waiting for user data script to complete (this may take 3-5 minutes)..."
sleep 180  # Wait 3 minutes for software installation

# Check if HTTP service is responding
log_info "Checking if web server is responding..."
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $TEMP_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ "$PUBLIC_IP" != "None" ] && [ -n "$PUBLIC_IP" ]; then
    log_info "Instance public IP: $PUBLIC_IP"
    
    # Test HTTP connectivity (with timeout)
    for i in {1..10}; do
        if curl -s --connect-timeout 5 "http://$PUBLIC_IP" > /dev/null; then
            log_success "Web server is responding"
            break
        else
            log_info "Attempt $i/10: Web server not ready yet, waiting..."
            sleep 30
        fi
    done
fi

# Stop the instance before creating AMI
log_info "Stopping instance before AMI creation..."
aws ec2 stop-instances --instance-ids $TEMP_INSTANCE_ID --region $AWS_REGION

# Wait for instance to be stopped
log_info "Waiting for instance to stop..."
aws ec2 wait instance-stopped --instance-ids $TEMP_INSTANCE_ID --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "Instance stopped successfully"
else
    log_error "Timeout waiting for instance to stop"
    exit 1
fi

# Create AMI from the stopped instance
log_info "Creating AMI from instance $TEMP_INSTANCE_ID..."
AMI_NAME="${PROJECT_NAME}-custom-ami-$(date +%Y%m%d-%H%M%S)"

AMI_ID=$(aws ec2 create-image \
    --instance-id $TEMP_INSTANCE_ID \
    --name "$AMI_NAME" \
    --description "Custom AMI for $PROJECT_NAME with Apache web server" \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=image,Tags=[{$TAG_PROJECT},{$TAG_ENVIRONMENT},{$TAG_OWNER},{Key=Name,Value=$AMI_NAME}]" \
    --query 'ImageId' \
    --output text)

if [ $? -eq 0 ] && [ "$AMI_ID" != "None" ]; then
    log_success "AMI creation initiated: $AMI_ID"
    
    # Update variables file
    sed -i "s/^export AMI_ID=.*/export AMI_ID=\"$AMI_ID\"/" "$(dirname "$0")/variables.sh"
else
    log_error "Failed to create AMI"
    exit 1
fi

# Wait for AMI to be available
log_info "Waiting for AMI to become available (this can take 5-10 minutes)..."
aws ec2 wait image-available --image-ids $AMI_ID --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "AMI is now available"
    
    # Get snapshot ID for cleanup purposes
    SNAPSHOT_ID=$(aws ec2 describe-images \
        --image-ids $AMI_ID \
        --region $AWS_REGION \
        --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' \
        --output text)
    
    if [ "$SNAPSHOT_ID" != "None" ] && [ -n "$SNAPSHOT_ID" ]; then
        sed -i "s/^export SNAPSHOT_ID=.*/export SNAPSHOT_ID=\"$SNAPSHOT_ID\"/" "$(dirname "$0")/variables.sh"
        log_info "Associated snapshot ID: $SNAPSHOT_ID"
    fi
else
    log_error "Timeout waiting for AMI to become available"
fi

# Terminate temporary instance
log_info "Terminating temporary instance..."
aws ec2 terminate-instances --instance-ids $TEMP_INSTANCE_ID --region $AWS_REGION

if [ $? -eq 0 ]; then
    log_success "Temporary instance termination initiated"
else
    log_error "Failed to terminate temporary instance"
fi

# Display AMI information
log_info "AMI Details:"
aws ec2 describe-images \
    --image-ids $AMI_ID \
    --region $AWS_REGION \
    --query 'Images[0].{ImageId:ImageId,Name:Name,State:State,Architecture:Architecture,VirtualizationType:VirtualizationType}' \
    --output table

log_success "Custom AMI creation completed successfully!"
log_info "AMI ID: $AMI_ID"
log_info "AMI Name: $AMI_NAME"
log_info "Snapshot ID: $SNAPSHOT_ID"
log_info "Next step: Run ./07-launch-ec2.sh"
