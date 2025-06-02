#boto3 script to create an s3 bucket from the terminal 
#prerequisite - setup AWS CLI, configure AWS CLI To use ACCESS KEYS AND SECRET ACCESS KEYS, install python virtual environment, install boto3

import boto3
from botocore.exceptions import ClientError

def create_bucket(bucket_name, region=None):
    try:
        # If no region is specified, default to us-east-1 (AWS Free Tier default)
        if region is None or region == 'us-east-1':
            s3_client = boto3.client('s3')
            s3_client.create_bucket(Bucket=bucket_name)
        else:
            s3_client = boto3.client('s3', region_name=region)
            location = {'LocationConstraint': region}
            s3_client.create_bucket(Bucket=bucket_name,
                                    CreateBucketConfiguration=location)
        print(f"✅ Bucket '{bucket_name}' created successfully.")
    except ClientError as e:
        print(f"❌ Error: {e}")

# Usage
create_bucket("sales-inventory-torbita-project-bucket", region="us-east-1")
