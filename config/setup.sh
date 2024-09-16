#!/bin/bash
set -e
CODE_NAME=$(cat code_name)
rm code_name
echo $CODE_NAME
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt-get install -y python3.10 python3.10-venv python3.10-dev zip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws
rm awscliv2.zip

# Switch to ubuntu user and install Poetry
sudo -u ubuntu -i bash << EOF
  export PATH="/home/ubuntu/.local/bin:/usr/local/bin:$PATH"
  curl -sSL https://install.python-poetry.org | python3 -
  echo 'alias run="poetry run python main.py"' >> /home/ubuntu/.bashrc

  echo ".................................."
  echo "DOWNLOAD CODE FROM AWS S3..."
  echo ".................................."

  aws s3 cp s3://lumi-code/${CODE_NAME}-main.zip /home/ubuntu/
  cd /home/ubuntu
  unzip "${CODE_NAME}-main.zip" -d .
  rm "${CODE_NAME}-main.zip"
  cd "${CODE_NAME}-main"

  echo ".................................."
  echo "FETCHING SECRETS FROM AWS SSM..."
  echo ".................................."

  echo "ALPACA_API_KEY=\$(aws ssm get-parameter --name 'ALPACA_API_KEY' --with-decryption --query 'Parameter.Value' --output text)" >> .env
  echo "ALPACA_API_SECRET=\$(aws ssm get-parameter --name 'ALPACA_API_SECRET' --with-decryption --query 'Parameter.Value' --output text)" >> .env
  echo "ALPACA_IS_PAPER=True" >> .env
  echo "IS_BACKTESTING=False" >> .env

  poetry lock
  poetry install
EOF
