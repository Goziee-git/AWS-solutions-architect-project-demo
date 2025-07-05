import boto3
import json
import random
import time
from datetime import datetime, timezone

s3 = boto3.client('s3')
bucket_name = 'global-sensor-data-demo'  # Replace with your bucket name

cities = ['Tokyo', 'London', 'New_York', 'Delhi', 'Sydney']

def generate_data(city):
    return {
        "city": city,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "temperature": round(random.uniform(-10, 40), 2),
        "humidity": random.randint(20, 90),
        "pressure": random.randint(980, 1050)
    }

def upload_data():
    for city in cities:
        data = generate_data(city)
        file_name = f"{city}/{data['timestamp']}.json"
        s3.put_object(
            Bucket=bucket_name,
            Key=file_name,
            Body=json.dumps(data)
        )
        print(f"Uploaded: {file_name}")
        time.sleep(2)

if __name__ == '__main__':
    upload_data()