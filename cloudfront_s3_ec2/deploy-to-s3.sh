#!/bin/bash

# S3 Static Website Deployment Script
# This script automates the deployment of a static website to an S3 bucket

# Configuration
BUCKET_NAME="your-bucket-name"  # Replace with your actual bucket name
REGION="us-east-1"              # Replace with your preferred region
WEBSITE_DIR="./sample-website"  # Directory containing your website files

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== S3 Static Website Deployment ===${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if the website directory exists
if [ ! -d "$WEBSITE_DIR" ]; then
    echo -e "${RED}Error: Website directory '$WEBSITE_DIR' not found.${NC}"
    exit 1
fi

# Create S3 bucket if it doesn't exist
echo -e "${YELLOW}Checking if bucket exists...${NC}"
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo -e "${YELLOW}Creating S3 bucket: $BUCKET_NAME${NC}"
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create bucket. Exiting.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Bucket created successfully.${NC}"
else
    echo -e "${GREEN}Bucket already exists.${NC}"
fi

# Enable static website hosting
echo -e "${YELLOW}Configuring bucket for static website hosting...${NC}"
aws s3 website "s3://$BUCKET_NAME" \
    --index-document index.html \
    --error-document error.html

# Set bucket policy for public read access
echo -e "${YELLOW}Setting bucket policy for public read access...${NC}"
POLICY='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::'$BUCKET_NAME'/*"
        }
    ]
}'

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "$POLICY"

# Upload website files
echo -e "${YELLOW}Uploading website files...${NC}"
aws s3 sync "$WEBSITE_DIR" "s3://$BUCKET_NAME" --delete

# Set appropriate content types
echo -e "${YELLOW}Setting content types...${NC}"
find "$WEBSITE_DIR" -name "*.html" | while read -r file; do
    relative_path="${file#$WEBSITE_DIR/}"
    aws s3 cp "s3://$BUCKET_NAME/$relative_path" "s3://$BUCKET_NAME/$relative_path" --content-type "text/html" --metadata-directive REPLACE
done

find "$WEBSITE_DIR" -name "*.css" | while read -r file; do
    relative_path="${file#$WEBSITE_DIR/}"
    aws s3 cp "s3://$BUCKET_NAME/$relative_path" "s3://$BUCKET_NAME/$relative_path" --content-type "text/css" --metadata-directive REPLACE
done

find "$WEBSITE_DIR" -name "*.js" | while read -r file; do
    relative_path="${file#$WEBSITE_DIR/}"
    aws s3 cp "s3://$BUCKET_NAME/$relative_path" "s3://$BUCKET_NAME/$relative_path" --content-type "application/javascript" --metadata-directive REPLACE
done

# Display website URL
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com${NC}"
echo -e "${YELLOW}Note: It may take a few minutes for the changes to propagate.${NC}"

# Additional information
echo -e "\n${YELLOW}=== Next Steps ===${NC}"
echo -e "1. To use a custom domain, configure Route 53 and create an alias record."
echo -e "2. For HTTPS support, set up CloudFront with an SSL certificate."
echo -e "3. For better performance, consider enabling CloudFront caching."
