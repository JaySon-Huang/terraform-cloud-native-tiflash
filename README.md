```
aws sso login
ssh-keygen -t rsa -b 4096 -f ./master_key -q -N ""
# init the terraform env
terraform init
# validate the terraform scripts
terraform validate

# create the deployment
terraform apply -auto-approve
`terraform output -raw ssh-center`

terraform refresh
terraform destroy -auto-approve
```
