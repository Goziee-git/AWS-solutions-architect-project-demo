#code runs query on s3 bucket initated by athena

import boto3

athena = boto3.client('athena')

response = athena.start_query_execution(
    QueryString='SELECT * FROM my_database.my_table LIMIT 5;',
    QueryExecutionContext={'Database': 'my_database'},
    ResultConfiguration={
        'OutputLocation': 's3://athena-query-result-from-s3/'
    }
)

print("Query Execution ID:", response['QueryExecutionId'])

# output of this code is the query ID 
