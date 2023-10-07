#!/bin/bash

CLUSTER_NAME="your-cluster-name"
REGION="ap-northeast-2"  # 한국 (Seoul)
ROLE_NAME="EKS-Cluster-Role"

aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy-cluster.json
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)

VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

SUBNET_IDS=""
AZ_COUNT=0
for AZ in $(aws ec2 describe-availability-zones --region $REGION --query 'AvailabilityZones[].ZoneName' --output text)
do
    SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --availability-zone $AZ --cidr-block "10.0.$((AZ_COUNT + 1)).0/24" --query 'Subnet.SubnetId' --output text)
    SUBNET_IDS="$SUBNET_IDS,$SUBNET_ID"
    AZ_COUNT=$((AZ_COUNT+1))
    if [ $AZ_COUNT -eq 2 ]; then
        break
    fi
done
SUBNET_IDS=$(echo $SUBNET_IDS | sed 's/^.//')

SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name EKS-SG --description "EKS Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text)

aws eks create-cluster \
  --name $CLUSTER_NAME \
  --role-arn $ROLE_ARN \
  --resources-vpc-config subnetIds=$SUBNET_IDS,securityGroupIds=$SECURITY_GROUP_ID \
  --region $REGION
