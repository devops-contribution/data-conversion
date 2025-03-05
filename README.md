# data-conversion

## How to start?

Make a zip of the Python code and keep it in the `terraform` folder.

```
cd scripts/
zip lambda_function.zip lambda_function.py
cp lambda_function.zip ../terraform/
cd ..
```

Run the following commands.
```
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

## Resources to be created
```
lambda function
event bridge
event bridge rule & target
2 s3 buckets
role - assumed by lambda
policy - associate with above role
sns topic
sns subscription
```

## Workflow:
You upload a CSV file to the S3 bucket named `custom-csv-bucket-velotio`, EventBridge captures this event and triggers the Lambda function. The Lambda function converts the CSV file into JSON and uploads it to the `custom-json-bucket-velotio` bucket, then sends an email alert to the subscriber.


## Destroy
```
cd terraform
terraform destroy -auto-approve
```
