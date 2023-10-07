#!/bin/bash

# Check and install unzip if not present
if ! command -v unzip &> /dev/null; then
    echo "unzip is not installed. Installing now..."
    sudo apt update && sudo apt install -y unzip
fi

# Installing AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip && sudo rm -r aws
echo "AWS CLI installation is complete."

# Configuring AWS
read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""  # newline for formatting
read -p "Default region name: " DEFAULT_REGION_NAME
read -p "Default output format [None]: " DEFAULT_OUTPUT_FORMAT

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $DEFAULT_REGION_NAME
aws configure set default.output $DEFAULT_OUTPUT_FORMAT

# Installing kubectl
echo "Installing kubectl..."
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.1/2023-04-19/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
echo "kubectl installation is complete."

# Checking kubectl version
kubectl version --short --client
