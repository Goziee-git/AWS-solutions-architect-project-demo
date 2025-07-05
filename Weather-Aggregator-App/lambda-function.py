import boto3
import json
import random
from datetime import datetime, timezone

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    city = 'Tokyo'  # You can deploy multiple Lambda functions for different cities
    data = {
        "city": city,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "temperature": round(random.uniform(-10, 40), 2),
        "humidity": random.randint(20, 90),
        "pressure": random.randint(980, 1050)
    }
    file_name = f"{city}/{data['timestamp']}.json"
    s3.put_object(
        Bucket='global-sensor-data-demo',
        Key=file_name,
        Body=json.dumps(data)
    )
    return {
        'statusCode': 200,
        'body': json.dumps('Sensor data uploaded to S3.')
    }