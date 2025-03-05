# data-conversion


## How to start?

Make zip of the python code and keep it in ```terraform``` folder.

```
cd scripts/
zip lambda_function.zip lambda_function.py
cp lambda_function.zip ../terraform/
cd ..
```

Now go to ```terraform``` folder and run below commands
```
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

## Resources to be created:
```
lambda function
event bridge
event bridge rule & target
2 s3 buckets
role   - assumed by lambda
policy - associate with above role
sns topic 
sns subscription
```


## So you upload a csv file to s3 bucket named ```custom-csv-bucket-velotio```, event bridge will capture this event and trigger the lambda to convert that csv into json and upload it to ```custom-json-bucket-velotio``` bucket and send an email alert to the subscriber.
