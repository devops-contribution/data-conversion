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
