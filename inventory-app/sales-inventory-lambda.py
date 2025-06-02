import json
import boto3
import uuid
import datetime

s3 = boto3.client('s3')
BUCKET_NAME = 'sales-inventory-torbita-project-bucket'

def lambda_handler(event, context):
    try:
        data = json.loads(event['body'])
        filename = f"inventory/{datetime.datetime.now().isoformat()}_{uuid.uuid4()}.json"

        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=filename,
            Body=json.dumps(data),
            ContentType='application/json'
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Success'})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
