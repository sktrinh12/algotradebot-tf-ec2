#!/bin/bash
set -e
CODE_NAME=$(cat code_name)
BROKER=$(cat broker | tr '[:lower:]' '[:upper:]')
rm broker
rm code_name
echo "CODE_NAME=${CODE_NAME}; BROKER=${BROKER}"
apt-get update
apt-get install -y software-properties-common zip
add-apt-repository -y ppa:deadsnakes/ppa
apt-get install -y python3.10 python3.10-venv python3.10-dev
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws
rm awscliv2.zip

# install Poetry, download code files from s3
sudo -u ubuntu -i bash << EOF
  export PATH="/home/ubuntu/.local/bin:/usr/local/bin:$PATH"
  curl -sSL https://install.python-poetry.org | python3 -
  echo 'alias run="poetry run python /home/ubuntu/${CODE_NAME}-main/main.py"' >> /home/ubuntu/.bashrc

  echo ".................................."
  echo "DOWNLOAD CODE FROM AWS S3..."
  echo ".................................."

  aws s3 cp s3://lumi-code/${CODE_NAME}-main.zip /home/ubuntu/
  cd /home/ubuntu/
  unzip "${CODE_NAME}-main.zip" -d .
  rm "${CODE_NAME}-main.zip"
EOF

# create a stop script
cat <<EOF > /home/ubuntu/stop.sh
  #!/bin/bash
  PID=\$(pgrep -f "poetry run python /home/ubuntu/${CODE_NAME}-main/main.py")
  if [ -n "\${PID}" ]; then
    kill "\${PID}"
    echo "Process with PID \${PID} has been killed."
  else
    echo "No process found for poetry run python main.py (${CODE_NAME})"
  fi
EOF

if [ "$BROKER" == "TRADIER" ]; then
  BROKER_LABEL_1="TRADIER_ACCESS_TOKEN"
  BROKER_LABEL_2="TRADIER_ACCOUNT_NUMBER"
else
  BROKER_LABEL_1="${BROKER}_API_KEY"
  BROKER_LABEL_2="${BROKER}_API_SECRET"
fi

echo ".................................."
echo "BROKER LABELS_1: ${BROKER_LABEL_1}"
echo "BROKER LABELS_2: ${BROKER_LABEL_2}"
echo ".................................."

chmod +x /home/ubuntu/stop.sh

# fetch secrets from ssm, then install packages
sudo -u ubuntu -i bash << EOF
  export PATH="/home/ubuntu/.local/bin:/usr/local/bin:$PATH"
  echo ".................................."
  echo "FETCHING SECRETS FROM AWS SSM..."
  echo ".................................."

  cd "${CODE_NAME}-main"
  echo "${BROKER_LABEL_1}=$(aws ssm get-parameter --name "${BROKER_LABEL_1}" --with-decryption --query 'Parameter.Value' --output text)" >> .env
  echo "${BROKER_LABEL_2}=$(aws ssm get-parameter --name "${BROKER_LABEL_2}" --with-decryption --query 'Parameter.Value' --output text)" >> .env
  echo "${BROKER}_IS_PAPER=True" >> .env
  echo "IS_BACKTESTING=False" >> .env

  # Add cron job to stop the process at 4:30 PM EST
  (crontab -l 2>/dev/null; echo "30 16 * * * /home/ubuntu/stop.sh") | crontab -

  poetry lock
  poetry install
EOF
