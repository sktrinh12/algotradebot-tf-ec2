## Trading bot on EC2

Deploy EC2 with minimal privleges. Terraform script expects `code_name` in order to download the proper code and valid `broker` that already exists on `aws ssm` to fetch the keys/secrets:
```
tf apply -auto-approve -var="code_name=${CODE_NAME} -var="broker=${BROKER}"
```

there is an alias for the poetry run command, simply type `run` and the python code will execute.
