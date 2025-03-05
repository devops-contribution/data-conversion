import json
import boto3
import os
import csv
from io import StringIO

# Initialize AWS Clients
s3 = boto3.client("s3")
sns = boto3.client("sns")

# Environment Variables
CSV_BUCKET = os.environ["CSV_BUCKET"] 
JSON_BUCKET = os.environ["JSON_BUCKET"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

def convert_csv_to_json(csv_data):
    """Convert CSV data to JSON format."""
    reader = csv.DictReader(StringIO(csv_data))
    json_data = json.dumps([row for row in reader], indent=4)
    return json_data

def send_email_alert(json_key):
    """Send an email alert via SNS when JSON is uploaded."""
    message = f"CSV file has been successfully converted and uploaded as {json_key} in {JSON_BUCKET}."
    subject = "CSV to JSON Conversion Completed"
    
    response = sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=message,
        Subject=subject
    )
    
    print(f"Email alert sent: {response}")

def lambda_handler(event, context):
    """Triggered when a CSV file is uploaded to Bucket 1."""
    try:
        # Check if the event comes from S3 Notification (Records exists)
        #if "Records" in event:
        #    csv_key = event["Records"][0]["s3"]["object"]["key"]
        
        # Check if the event comes from EventBridge (detail exists)
        #elif "detail" in event and "object" in event["detail"]:
        if "detail" in event and "object" in event["detail"]:
            csv_key = event["detail"]["object"]["key"]
        
        else:
            print("Unexpected event format:", json.dumps(event))
            return {"statusCode": 400, "body": "Invalid event format"}

        # Process only CSV files
        if not csv_key.endswith(".csv"):
            print(f"Skipping non-CSV file: {csv_key}")
            return {"statusCode": 200, "body": "Not a CSV file"}

        # Read CSV file from S3 (Bucket 1)
        response = s3.get_object(Bucket=CSV_BUCKET, Key=csv_key)
        file_content = response["Body"].read().decode("utf-8")

        # Convert CSV to JSON
        json_data = convert_csv_to_json(file_content)

        # Define new JSON file name
        json_key = csv_key.replace(".csv", ".json")

        # Upload JSON file to S3 (Bucket 2)
        s3.put_object(Bucket=JSON_BUCKET, Key=json_key, Body=json_data, ContentType="application/json")

        print(f"Converted {csv_key} to {json_key} and uploaded to {JSON_BUCKET}")

        # Send an email alert
        send_email_alert(json_key)

        return {"statusCode": 200, "body": f"Successfully processed {csv_key}"}

    except Exception as e:
        print(f"Error processing file {csv_key}: {str(e)}")
        return {"statusCode": 500, "body": f"Error processing {csv_key}"}

