import boto3

s3 = boto3.client('s3')

bucket = 'athena-query-result-from-s3'
prefix = 'Abuja-result/unsaved/2025/05/28/'

response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)

print("Files in S3:")
for obj in response.get('Contents', []):
    print(obj['Key'])
