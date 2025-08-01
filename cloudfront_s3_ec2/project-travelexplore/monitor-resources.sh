#!/bin/bash

# TravelExplore Resource Monitoring Script
# This script monitors the health and performance of TravelExplore resources

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PRIMARY_BUCKET="travelexplore-assets-primary"
EUROPE_BUCKET="travelexplore-assets-europe"
ASIA_BUCKET="travelexplore-assets-asia"
US_INSTANCE_ID="i-0abc123def456789"
EU_INSTANCE_ID="i-0def456789abc123"
AP_INSTANCE_ID="i-0789abc123def456"
CLOUDFRONT_DIST_ID="E1ABCDEFGHIJKL"

echo -e "${BLUE}=== TravelExplore Resource Monitoring ===${NC}"
echo "Date: $(date)"
echo "----------------------------------------"

# Check AWS CLI availability
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Function to check S3 bucket status
check_s3_bucket() {
    local bucket_name=$1
    local region=$2
    
    echo -e "${YELLOW}Checking S3 bucket: ${bucket_name} (${region})${NC}"
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket "${bucket_name}" --region "${region}" 2>/dev/null; then
        echo -e "${GREEN}✓ Bucket exists${NC}"
        
        # Get bucket versioning status
        versioning=$(aws s3api get-bucket-versioning --bucket "${bucket_name}" --region "${region}" --query 'Status' --output text)
        if [[ "${versioning}" == "Enabled" ]]; then
            echo -e "${GREEN}✓ Versioning is enabled${NC}"
        else
            echo -e "${RED}✗ Versioning is not enabled${NC}"
        fi
        
        # Get object count
        object_count=$(aws s3 ls s3://"${bucket_name}" --recursive --summarize --region "${region}" | grep "Total Objects" | awk '{print $3}')
        echo -e "${BLUE}ℹ Total objects: ${object_count}${NC}"
        
        # Get bucket size
        bucket_size=$(aws s3 ls s3://"${bucket_name}" --recursive --summarize --region "${region}" | grep "Total Size" | awk '{print $3 " " $4}')
        echo -e "${BLUE}ℹ Total size: ${bucket_size}${NC}"
    else
        echo -e "${RED}✗ Bucket does not exist or you don't have access${NC}"
    fi
    
    echo "----------------------------------------"
}

# Function to check EC2 instance status
check_ec2_instance() {
    local instance_id=$1
    local region=$2
    local name=$3
    
    echo -e "${YELLOW}Checking EC2 instance: ${name} (${instance_id}) in ${region}${NC}"
    
    # Get instance status
    status=$(aws ec2 describe-instance-status --instance-ids "${instance_id}" --region "${region}" --query 'InstanceStatuses[0].InstanceStatus.Status' --output text)
    
    if [[ "${status}" == "ok" ]]; then
        echo -e "${GREEN}✓ Instance status: OK${NC}"
        
        # Get instance details
        instance_type=$(aws ec2 describe-instances --instance-ids "${instance_id}" --region "${region}" --query 'Reservations[0].Instances[0].InstanceType' --output text)
        echo -e "${BLUE}ℹ Instance type: ${instance_type}${NC}"
        
        # Get CPU utilization (last 5 minutes)
        cpu_util=$(aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value="${instance_id}" --start-time "$(date -u -v-5M '+%Y-%m-%dT%H:%M:%SZ')" --end-time "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" --period 300 --statistics Average --region "${region}" --query 'Datapoints[0].Average' --output text)
        
        if [[ "${cpu_util}" != "None" ]]; then
            cpu_util=$(printf "%.2f" "${cpu_util}")
            echo -e "${BLUE}ℹ CPU utilization (last 5 min): ${cpu_util}%${NC}"
            
            if (( $(echo "${cpu_util} > 80" | bc -l) )); then
                echo -e "${RED}⚠ High CPU utilization detected!${NC}"
            fi
        else
            echo -e "${YELLOW}ℹ CPU utilization data not available${NC}"
        fi
    else
        echo -e "${RED}✗ Instance status: ${status:-UNKNOWN}${NC}"
    fi
    
    echo "----------------------------------------"
}

# Function to check CloudFront distribution status
check_cloudfront() {
    local dist_id=$1
    
    echo -e "${YELLOW}Checking CloudFront distribution: ${dist_id}${NC}"
    
    # Get distribution status
    status=$(aws cloudfront get-distribution --id "${dist_id}" --query 'Distribution.Status' --output text)
    
    if [[ "${status}" == "Deployed" ]]; then
        echo -e "${GREEN}✓ Distribution status: Deployed${NC}"
        
        # Get distribution details
        domain=$(aws cloudfront get-distribution --id "${dist_id}" --query 'Distribution.DomainName' --output text)
        echo -e "${BLUE}ℹ Domain name: ${domain}${NC}"
        
        # Get origin details
        origins=$(aws cloudfront get-distribution --id "${dist_id}" --query 'Distribution.DistributionConfig.Origins.Items[].DomainName' --output text)
        echo -e "${BLUE}ℹ Origins: ${origins}${NC}"
        
        # Get cache behavior details
        cache_behaviors=$(aws cloudfront get-distribution --id "${dist_id}" --query 'Distribution.DistributionConfig.CacheBehaviors.Items[].PathPattern' --output text)
        echo -e "${BLUE}ℹ Cache behaviors: ${cache_behaviors}${NC}"
    else
        echo -e "${RED}✗ Distribution status: ${status:-UNKNOWN}${NC}"
    fi
    
    echo "----------------------------------------"
}

# Check S3 buckets
check_s3_bucket "${PRIMARY_BUCKET}" "us-east-1"
check_s3_bucket "${EUROPE_BUCKET}" "eu-west-1"
check_s3_bucket "${ASIA_BUCKET}" "ap-northeast-1"

# Check EC2 instances
check_ec2_instance "${US_INSTANCE_ID}" "us-east-1" "US Web Server"
check_ec2_instance "${EU_INSTANCE_ID}" "eu-west-1" "EU Web Server"
check_ec2_instance "${AP_INSTANCE_ID}" "ap-northeast-1" "AP Web Server"

# Check CloudFront distribution
check_cloudfront "${CLOUDFRONT_DIST_ID}"

echo -e "${BLUE}=== Monitoring Complete ===${NC}"
echo "For detailed metrics, check CloudWatch dashboards."
