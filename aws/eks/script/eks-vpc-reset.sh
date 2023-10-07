#!/bin/bash

# Get VPC ID input
read -p "Enter the VPC ID to delete: " VPC_ID

# Detach & Delete Internet Gateway
echo "Detaching and deleting the Internet Gateway..."
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${VPC_ID}" --query 'InternetGateways[0].InternetGatewayId' --output text)
if [ "$IGW_ID" ]; then
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
fi

# Delete Route Table (only custom route tables, main route table will get deleted with VPC)
echo "Deleting Route Tables..."
RTB_IDS=($(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text))
for RTB_ID in "${RTB_IDS[@]}"; do
    ASSOCIATION_IDS=($(aws ec2 describe-route-tables --route-table-id $RTB_ID --query 'RouteTables[0].Associations[].RouteTableAssociationId' --output text))
    for ASSOC_ID in "${ASSOCIATION_IDS[@]}"; do
        aws ec2 disassociate-route-table --association-id $ASSOC_ID
    done
    aws ec2 delete-route-table --route-table-id $RTB_ID
done

# Delete Subnets
echo "Deleting Subnets..."
SUBNET_IDS=($(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[].SubnetId' --output text))
for SUBNET_ID in "${SUBNET_IDS[@]}"; do
    aws ec2 delete-subnet --subnet-id $SUBNET_ID
done

# Delete VPC
echo "Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "All resources have been deleted successfully."