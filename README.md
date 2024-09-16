## Lumibot trading bot on EC2

Deploy EC2 with minimal privleges. Terraform script expects `code_name` in order to download the proper code:
```
tf apply -auto-approve -var="code_name=${CODE_NAME}"
```

there is an alias for the poetry run command, simply type `run` and the python code will execute.
