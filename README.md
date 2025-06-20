```
aws sso login
ssh-keygen -t rsa -b 4096 -f ./master_key -q -N ""
terraform init
terraform apply -auto-approve
`terraform output -raw ssh-center`

terraform refresh
terraform destroy -auto-approve
```
