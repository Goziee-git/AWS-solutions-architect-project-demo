A company collects data for temperature, humidity, and atmospheric pressure in cities across multiple continents. The average volume of data that the company collects from each site daily is 500 GB. Each site has a high-speed Internet connection.
The company wants to aggregate the data from all these global sites as quickly as possible in a single Amazon S3 bucket. The solution must minimize operational complexity.
What is the solutions to this Question
- Turn on S3 Transfer Acceleration on the destination S3 bucket. Use multipart uploads to directly upload site data to the destination S3 bucket.

Project Goal
Simulate ingestion of temperature, humidity, and atmospheric pressure data from multiple global locations into a central S3 bucket as efficiently as possible using AWS Free Tier.

Free Tier Limitations (Key Points)
- Amazon S3: 5 GB standard storage, 20k GET, 2k PUT requests
- AWS Lambda: 1M requests/month, 400K GB-seconds compute time
- Amazon CloudWatch: 10 custom metrics, 5GB log data ingestion
- AWS Transfer Acceleration and Direct Connect are not free tier
- Amazon Kinesis is not fully free; avoid for cost reasons
- Amazon EC2: 750 hours/month (t2.micro/t3.micro)
- AWS Glue, Athena, DataSync are not in Free Tier or cost quickly

Given the 500 GB/day real data volume, we will simulate a smaller volume for the demo (say ~1 GB or less/day total), but design the solution so that it could scale later.

>> ✅ High-Level Architecture (Simplified for Demo)
We simulate multiple edge locations (representing continents) using:
- A Python script (run on EC2 or locally)
- Lambda functions to process and forward data
- S3 bucket as centralized storage

>>✅ Step 1: Setup the Central S3 Bucket
a. Create the S3 Bucket
Go to Amazon S3 in the AWS Console
Click Create bucket
Name: global-sensor-data-demo
Region: us-east-1 (cheapest + most supported)
Uncheck Block all public access (if needed for testing, otherwise leave secure)
Enable Versioning (optional)
Create Bucket

>>✅ Step 2: Simulate Sensor Data (Client Side)
our json data output in our bucket will look this this
You will simulate multiple global edge devices (cities) sending JSON files.
{
  "city": "Tokyo",
  "timestamp": "2025-05-27T12:34:56Z",
  "temperature": 24.3,
  "humidity": 68,
  "pressure": 1013
}
b. Create Python Script to Simulate Uploads
This script can be run on your local machine or an EC2 instance (Free Tier).
see simulate-upload.py
✅ Tip: Use boto3 and aws configure to setup AWS credentials.


✅ Step 3: Automate with AWS Lambda (Optional)
Permissions: create new role with basic Lambda permissions
Code example:
see lambda-function.py

✅ Step 4: Verify Aggregated Data in S3
Open the S3 bucket
Browse folders per city
View individual JSON files

✅ Step 5: Analyze Data with Athena (Optional)
This part is partially free for up to 1TB of query/month (pay for data scanned).
a. Create a table in Athena (from S3 JSON)

CREATE EXTERNAL TABLE sensor_data (
  city string,
  timestamp string,
  temperature float,
  humidity int,
  pressure int
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://global-sensor-data-demo/';

b. Query Example
sql
CopyEdit
SELECT city, avg(temperature) as avg_temp
FROM sensor_data
GROUP BY city;


DIFFERENCES BETWEEN THE APPROACHES
✅ Use Case #1: Local Sensor Data Injection to S3 Using Python Script
🎯 Goal
You want to simulate multiple sensors (from different global cities) and upload their data to an Amazon S3 bucket, all done from your local computer using a Python script.

📦 What’s in the Script? (simulate_upload.py)
The script does three main things:
Loops over a list of cities (like Tokyo, London, etc.)
Generates random sensor data (temperature, humidity, pressure) for each city
Uploads the data to S3 as a JSON file under a folder named after the city
Example upload path in S3:
s3://global-sensor-data-demo/Tokyo/2025-05-27T14:33:00Z.json

✅ Use Case #2: Automated Sensor Data Upload Using AWS Lambda
🎯 Goal
Instead of relying on a local machine to simulate and upload data, this use case uses an AWS Lambda function to automatically generate and send sensor data to your Amazon S3 bucket from within the AWS cloud.

🔄 Key Difference from Use Case #1
Feature	Use Case 1: Local Script	                                 Use Case 2: Lambda Function (Cloud)
Runs Where?	On your local computer	                                - Inside AWS (fully managed)
Triggered By?	Manual run via terminal	                             - Automatically (via schedule or event)
Latency to AWS	Depends on your Internet speed	                    - Low (runs in same region as S3)
Operational Load	You must keep your script running                 - AWS handles execution & scaling
Use of Free Tier	Local resources (no AWS usage)	                 - Uses Lambda Free Tier (1M requests/month)


Step	Description
1️⃣	Create an S3 bucket
2️⃣	Prepare your Lambda code
3️⃣	Create an IAM role for Lambda
4️⃣	Deploy your Lambda function
5️⃣	Create a schedule to trigger every 5 minutes
6️⃣	Verify data in S3

🔐 Step 3: Create an IAM Role for Lambda
- Go to IAM Console → Roles
- Click “Create role”
- Choose "Lambda" as the use case, click Next
- Attach the following policy:
- AmazonS3FullAccess (or more secure: custom policy to access only your bucket)
- Name it: LambdaS3SensorRole
- Click “Create role”

📦 Step 4: Deploy the Lambda Function
- Go to AWS Lambda Console
- Click “Create function”
- Choose “Author from scratch”
- Function name: SensorUploader_Tokyo
- Runtime: Python 3.9 (or latest supported)
- Permissions: Choose “Use an existing role”, then pick LambdaS3SensorRole
- Click Create function

🧠 Once created:
- Scroll to Function code
- In the inline editor, paste the lambda_function.py code
- Click Deploy
✅ You’ve now deployed the Lambda function!

⏱️ Step 5: Schedule Lambda to Run Every 5 Minutes
- In the same Lambda function screen, go to “Triggers”
- Click “Add trigger”
- Choose “EventBridge (CloudWatch Events)”
- Click “Create a new rule”
- Name it: RunEvery5Minutes
- Rule type: Schedule expression
- Expression: rate(5 minutes)
- Click Add
✅ This will trigger your Lambda every 5 minutes 🎯

📂 Step 6: Verify Your Data in S3
- After 5–10 minutes:
- Go to your S3 bucket in the AWS Console
- You should see folders like /Tokyo/ with .json files
- Open a file — it will contain simulated temperature, humidity, and pressure data

📊 Step-by-Step: Create CloudWatch Dashboard
🔹 Step 1: Open CloudWatch Console
- Go to Amazon CloudWatch
- In the left menu, click Dashboards
- Click Create dashboard
- Name your dashboard: "SensorLambdaMonitoring"
- Click Create dashboard

📈 Step 2: Add Invocation Count Widget
Choose “Line” widget → Click Next
In the “Browse” tab:
Choose “Lambda Metrics”
Choose SensorUploader_Tokyo under “Function Name”
Select Invocations
Click Create widget

🕓 Step 3: Add Duration Widget
Click “Add widget” (top-right)
Choose “Line” → Click Next
Select SensorUploader_Tokyo again
Check the box for Duration
Click Create widget

🔧 Step 5: Customize Time Range & Refresh
At the top of your dashboard:
Set Period to 5 minutes
Set Time range to Last 1 hour or Last 3 hours
Check Auto refresh (e.g., every 1 minute) for live updates

✅ Now you’re seeing near real-time Lambda execution metrics!

🧠 Tip: Optional Enhancements
➕ Add More Cities
Repeat these steps for each new Lambda function (e.g., SensorUploader_London, SensorUploader_Delhi) to monitor all simulated global sensors.

📧 Set Alarms
You can add CloudWatch Alarms to:
Notify you (via email/SNS) if error count > 0
Alert if function duration spikes (e.g., >1000ms)
Would you like a follow-up to add alerts or a way to export this setup as code for reuse?

🎯 But Now What?
- You’ve got structured data in S3... but:
- How do you query it?
- How do you analyze trends (e.g., average temperature per city per day)?
- How do you generate reports or visualize patterns?

AMAZON ATHENA: It lets you run SQL queries directly against your data in S3. No need for a database, ETL, or moving data
Step 1: Create a Glue Table for Athena
** using GLUE is very important because the structure of the data in the s3 bucket may not be queriable so we have to use glue to make the data object queriable
- Athena uses AWS Glue to understand your data schema.
- Go to AWS Glue (AWS GLUE -IS A SERVERLESS DATA INJESTION SERVICE) 
 WE NEED TO SET UP AWS GLUE TO 
Scan your S3 sensor data (global-sensor-data-demo)
Automatically detect schema (temperature, humidity, etc.)
Make it queryable from Athena using SQL
- Create a new crawler:
- Source: Your S3 bucket
- Output: New Glue database (e.g., sensor_data_db)
- Run the crawler
- It creates a table representing your sensor data








