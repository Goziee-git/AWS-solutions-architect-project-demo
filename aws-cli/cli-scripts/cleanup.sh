#!/bin/bash

# Script: cleanup.sh
# Purpose: Clean up all AWS resources created by this project
# Usage: ./cleanup.sh

# Source variables
source "$(dirname "$0")/variables.sh"

log_warning "🧹 Starting cleanup of AWS resources..."
log_warning "This will delete ALL resources created by this project!"

# Confirmation prompt
read -p "Are you sure you want to delete all resources? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    log_info "Cleanup cancelled"
    exit 0
fi

# Track cleanup progress
CLEANUP_ERRORS=0

# Function to handle cleanup errors
handle_error() {
    local service=$1
    local resource=$2
    log_error "Failed to delete $service: $resource"
    ((CLEANUP_ERRORS++))
}

# 1. Terminate EC2 Instance
if [ -n "$INSTANCE_ID" ]; then
    log_info "Terminating EC2 instance: $INSTANCE_ID"
    if aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $AWS_REGION &> /dev/null; then
        log_success "Instance termination initiated"
        
        # Wait for termination
        log_info "Waiting for instance to terminate..."
        if aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $AWS_REGION; then
            log_success "Instance terminated successfully"
        else
            log_warning "Timeout waiting for instance termination"
        fi
    else
        handle_error "EC2 Instance" "$INSTANCE_ID"
    fi
else
    log_info "No EC2 instance to terminate"
fi

# 2. Deregister AMI and delete snapshot
if [ -n "$AMI_ID" ]; then
    log_info "Deregistering AMI: $AMI_ID"
    if aws ec2 deregister-image --image-id $AMI_ID --region $AWS_REGION &> /dev/null; then
        log_success "AMI deregistered successfully"
        
        # Delete associated snapshot
        if [ -n "$SNAPSHOT_ID" ]; then
            log_info "Deleting snapshot: $SNAPSHOT_ID"
            sleep 10  # Wait a bit for AMI deregistration to complete
            if aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID --region $AWS_REGION &> /dev/null; then
                log_success "Snapshot deleted successfully"
            else
                handle_error "EBS Snapshot" "$SNAPSHOT_ID"
            fi
        fi
    else
        handle_error "AMI" "$AMI_ID"
    fi
else
    log_info "No AMI to deregister"
fi

# 3. Delete Security Group
if [ -n "$SECURITY_GROUP_ID" ]; then
    log_info "Deleting security group: $SECURITY_GROUP_ID"
    # Wait a bit to ensure instance is fully terminated
    sleep 15
    if aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID --region $AWS_REGION &> /dev/null; then
        log_success "Security group deleted successfully"
    else
        handle_error "Security Group" "$SECURITY_GROUP_ID"
    fi
else
    log_info "No security group to delete"
fi

# 4. Delete Route Table (only if it's not the main route table)
if [ -n "$ROUTE_TABLE_ID" ]; then
    log_info "Checking if route table can be deleted: $ROUTE_TABLE_ID"
    
    # Check if it's the main route table
    IS_MAIN=$(aws ec2 describe-route-tables \
        --route-table-ids $ROUTE_TABLE_ID \
        --region $AWS_REGION \
        --query 'RouteTables[0].Associations[?Main==`true`]' \
        --output text)
    
    if [ -z "$IS_MAIN" ]; then
        log_info "Deleting custom route table: $ROUTE_TABLE_ID"
        if aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID --region $AWS_REGION &> /dev/null; then
            log_success "Route table deleted successfully"
        else
            handle_error "Route Table" "$ROUTE_TABLE_ID"
        fi
    else
        log_info "Skipping main route table deletion"
    fi
else
    log_info "No custom route table to delete"
fi

# 5. Detach and Delete Internet Gateway
if [ -n "$IGW_ID" ] && [ -n "$VPC_ID" ]; then
    log_info "Detaching Internet Gateway: $IGW_ID"
    if aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $AWS_REGION &> /dev/null; then
        log_success "Internet Gateway detached successfully"
        
        log_info "Deleting Internet Gateway: $IGW_ID"
        if aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $AWS_REGION &> /dev/null; then
            log_success "Internet Gateway deleted successfully"
        else
            handle_error "Internet Gateway" "$IGW_ID"
        fi
    else
        handle_error "Internet Gateway Detachment" "$IGW_ID"
    fi
else
    log_info "No Internet Gateway to delete"
fi

# 6. Delete Subnets
if [ -n "$PUBLIC_SUBNET_ID" ]; then
    log_info "Deleting public subnet: $PUBLIC_SUBNET_ID"
    if aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID --region $AWS_REGION &> /dev/null; then
        log_success "Public subnet deleted successfully"
    else
        handle_error "Public Subnet" "$PUBLIC_SUBNET_ID"
    fi
else
    log_info "No public subnet to delete"
fi

if [ -n "$PRIVATE_SUBNET_ID" ]; then
    log_info "Deleting private subnet: $PRIVATE_SUBNET_ID"
    if aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID --region $AWS_REGION &> /dev/null; then
        log_success "Private subnet deleted successfully"
    else
        handle_error "Private Subnet" "$PRIVATE_SUBNET_ID"
    fi
else
    log_info "No private subnet to delete"
fi

# 7. Delete VPC
if [ -n "$VPC_ID" ]; then
    log_info "Deleting VPC: $VPC_ID"
    # Wait a bit for all resources to be fully deleted
    sleep 10
    if aws ec2 delete-vpc --vpc-id $VPC_ID --region $AWS_REGION &> /dev/null; then
        log_success "VPC deleted successfully"
    else
        handle_error "VPC" "$VPC_ID"
    fi
else
    log_info "No VPC to delete"
fi

# 8. Clear variables file
log_info "Clearing resource IDs from variables file..."
VARS_FILE="$(dirname "$0")/variables.sh"
sed -i 's/^export VPC_ID=.*/export VPC_ID=""/' "$VARS_FILE"
sed -i 's/^export PUBLIC_SUBNET_ID=.*/export PUBLIC_SUBNET_ID=""/' "$VARS_FILE"
sed -i 's/^export PRIVATE_SUBNET_ID=.*/export PRIVATE_SUBNET_ID=""/' "$VARS_FILE"
sed -i 's/^export IGW_ID=.*/export IGW_ID=""/' "$VARS_FILE"
sed -i 's/^export ROUTE_TABLE_ID=.*/export ROUTE_TABLE_ID=""/' "$VARS_FILE"
sed -i 's/^export SECURITY_GROUP_ID=.*/export SECURITY_GROUP_ID=""/' "$VARS_FILE"
sed -i 's/^export AMI_ID=.*/export AMI_ID=""/' "$VARS_FILE"
sed -i 's/^export INSTANCE_ID=.*/export INSTANCE_ID=""/' "$VARS_FILE"
sed -i 's/^export SNAPSHOT_ID=.*/export SNAPSHOT_ID=""/' "$VARS_FILE"

# Summary
echo -e "\n${BLUE}=== Cleanup Summary ===${NC}"
if [ $CLEANUP_ERRORS -eq 0 ]; then
    log_success "🎉 All resources cleaned up successfully!"
    log_info "No AWS charges should continue from this project"
else
    log_warning "⚠️  Cleanup completed with $CLEANUP_ERRORS errors"
    log_info "Please check AWS Console to verify all resources are deleted"
    log_info "Some resources may need manual deletion"
fi

# Verification commands
echo -e "\n${YELLOW}=== Verification Commands ===${NC}"
echo -e "Check remaining VPCs: ${BLUE}aws ec2 describe-vpcs --filters 'Name=tag:Project,Values=$PROJECT_NAME'${NC}"
echo -e "Check remaining instances: ${BLUE}aws ec2 describe-instances --filters 'Name=tag:Project,Values=$PROJECT_NAME' 'Name=instance-state-name,Values=running,pending,stopping,stopped'${NC}"
echo -e "Check remaining AMIs: ${BLUE}aws ec2 describe-images --owners self --filters 'Name=tag:Project,Values=$PROJECT_NAME'${NC}"

# Cost monitoring reminder
echo -e "\n${YELLOW}=== Cost Monitoring ===${NC}"
echo -e "💰 Monitor your AWS bill at: https://console.aws.amazon.com/billing/"
echo -e "💰 Set up billing alerts to avoid unexpected charges"
echo -e "💰 Most resources are deleted immediately, but some charges may appear with delay"

log_info "Cleanup process completed!"

# Final check for any remaining tagged resources
log_info "Performing final check for remaining resources..."
REMAINING_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=$PROJECT_NAME" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text \
    --region $AWS_REGION)

if [ -n "$REMAINING_INSTANCES" ] && [ "$REMAINING_INSTANCES" != "None" ]; then
    log_warning "Found remaining instances: $REMAINING_INSTANCES"
else
    log_success "No remaining instances found"
fi
