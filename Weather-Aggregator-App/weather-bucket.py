import boto3

# Force use of us-east-1 region explicitly
s3 = boto3.client('s3', region_name='us-east-1')

bucket_name = 'weather-bucket'

try:
    # No CreateBucketConfiguration for us-east-1
    s3.create_bucket(Bucket=bucket_name)
    print(f"Bucket '{bucket_name}' created successfully in 'us-east-1'.")
except s3.exceptions.BucketAlreadyOwnedByYou:
    print(f"Bucket '{bucket_name}' already exists and is owned by you.")
except Exception as e:
    print(f"Error creating bucket: {e}")
