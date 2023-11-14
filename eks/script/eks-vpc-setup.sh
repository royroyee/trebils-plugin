#!/bin/bash

# Get VPC CIDR block input
read -p "Enter the CIDR block for the VPC (e.g., 10.0.0.0/16): " VPC_CIDR

# Get tag names input
read -p "Enter the name for the VPC: " VPC_NAME
read -p "Enter the cluster name: " CLUSTER_NAME
read -p "Enter the prefix for subnet names: " SUBNET_NAME_PREFIX
read -p "Enter the name for the internet gateway: " INTERNET_GATEWAY_NAME

# Create the VPC
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=${VPC_NAME} Key=kubernetes.io/cluster/${CLUSTER_NAME},Value=shared

# Get available zones
AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[*].ZoneName' --output text))

# Create the subnets
echo "Creating subnets..."
SUBNET_IDS=()
for i in "${!AZS[@]}"; do
    SUBNET_CIDR="10.0.${i}.0/24"
    SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --availability-zone ${AZS[$i]} --cidr-block $SUBNET_CIDR --query 'Subnet.SubnetId' --output text)
    aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value=${SUBNET_NAME_PREFIX}-${i} Key=kubernetes.io/cluster/${CLUSTER_NAME},Value=shared
    aws ec2 modify-subnet-attribute --subnet-id $SUBNET_ID --map-public-ip-on-launch
    SUBNET_IDS+=($SUBNET_ID)
done

# Create Internet Gateway and attach to the VPC
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=${INTERNET_GATEWAY_NAME}
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Create a Route Table and associate with the subnets
RTB_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
for SUBNET_ID in "${SUBNET_IDS[@]}"; do
    aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $RTB_ID > /dev/null
done

echo "VPC, Subnets, Internet Gateway, and Route Table have been successfully created."
echo "VPC ID: $VPC_ID"
echo "Internet Gateway ID: $IGW_ID"
echo "Route Table ID: $RTB_ID"
