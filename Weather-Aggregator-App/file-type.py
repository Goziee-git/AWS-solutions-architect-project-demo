import boto3

s3 = boto3.client('s3')

bucket = 'global-sensor-data-demo' #Bucket name
key = 'Tokyo/2025-05-27T11:46:47.963361+00:00.json'  # Replace with your actual file name

response = s3.get_object(Bucket=bucket, Key=key)
data = response['Body'].read().decode('utf-8')

print(data)  # This prints the content of your JSON file
