import boto3
from boto3.s3.transfer import TransferConfig

s3 = boto3.client('s3', endpoint_url='https://s3-accelerate.amazonaws.com')

config = TransferConfig(multipart_threshold=5*1024*1024, multipart_chunksize=5*1024*1024)

s3.upload_file(
    Filename='testfile.bin',
    Bucket='my-transfer-demo-bucket-12345',
    Key='testfile.bin',
    Config=config
)
