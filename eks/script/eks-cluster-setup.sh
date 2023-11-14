#!/bin/bash



create_vpc_and_subnets() {
  read -p "Enter the VPC name: " VPC_NAME

  while true; do
    read -p "Enter the CIDR block for the VPC (e.g., 10.0.0.0/16): " CIDR_BLOCK
    if [[ $CIDR_BLOCK =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        break
    else
        echo "Invalid CIDR format. Please enter in the format xxx.xxx.xxx.xxx/xx"
    fi
  done

  VPC_ID=$(aws ec2 create-vpc --cidr-block $CIDR_BLOCK --query 'Vpc.VpcId' --output text)

  aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value="$VPC_NAME"

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

  SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name "eks-$CLUSTER_NAME-sg" --description "EKS Cluster Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text --region $REGION)

  aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol all --cidr $CIDR_BLOCK --region $REGION

  echo "VPC, Subnets, and Security Group with the name $VPC_NAME have been created."
}


create_cluster_role() {
  read -p "Enter the Cluster name: " $CLUSTER_NAME

  # Create an IAM role for EKS Cluster
  CLUSTER_ROLE_NAME="EKS-Cluster-Role-$CLUSTER_NAME"
  aws iam create-role --role-name $CLUSTER_ROLE_NAME --assume-role-policy-document file://trust-policy-cluster.json
  aws iam attach-role-policy --role-name $CLUSTER_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
  aws iam attach-role-policy --role-name $CLUSTER_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController

  CLUSTER_ROLE_ARN=$(aws iam get-role --role-name $CLUSTER_ROLE_NAME --query 'Role.Arn' --output text)
}

create_node_role() {
  read -p "Enter the Cluster name: " $CLUSTER_NAME

  # Create an IAM role for EKS Worker Nodes
  NODE_ROLE_NAME="EKS-Node-Role-$CLUSTER_NAME"
  aws iam create-role --role-name $NODE_ROLE_NAME --assume-role-policy-document file://trust-policy-node.json
  aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
  aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
  aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

  NODE_ROLE_ARN=$(aws iam get-role --role-name $NODE_ROLE_NAME --query 'Role.Arn' --output text)
}

create_eks_cluster() {
    read -p "Enter the Cluster name: " $CLUSTER_NAME

    # Create EKS Cluster
    if ! aws eks create-cluster \
        --name "$CLUSTER_NAME" \
        --role-arn "$CLUSTER_ROLE_ARN" \
        --resources-vpc-config subnetIds="$SUBNET_IDS",securityGroupIds="$SECURITY_GROUP_ID" \
        --region $REGION; then
        echo "Error: Failed to create EKS cluster."
        return 1
    fi

    # Check Cluster status until it's ACTIVE
    local MAX_RETRIES=10
    local COUNT=0

    while [[ $(aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.status' --output text 2>/dev/null) != "ACTIVE" ]]; do
        if [[ $COUNT -eq $MAX_RETRIES ]]; then
            echo "Error: Exceeded maximum retries waiting for EKS cluster to become ACTIVE."
            return 1
        fi

        echo "Waiting for EKS cluster to become ACTIVE... Attempt $((COUNT+1))/$MAX_RETRIES"
        sleep 60
        COUNT=$((COUNT+1))
    done

    echo "EKS cluster is now ACTIVE."
    return 0
}

create_node_group() {
  # Create Node Group
  read -p "Enter the node group name: " NODE_GROUP_NAME
  read -p "Enter the AMI ID for worker nodes (e.g., ami-0c55b159cbfafe1f0 for EKS optimized AMI): " NODE_AMI_ID
  read -p "Enter the instance type for worker nodes (e.g., m5.large): " NODE_INSTANCE_TYPE
  read -p "Enter the desired node count: " NODE_COUNT

  aws eks create-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP_NAME --scaling-config minSize=1,maxSize=3,desiredSize=$NODE_COUNT --subnets $SUBNET_IDS --node-role $NODE_ROLE_ARN --ami-type AL2_x86_64 --instance-types $NODE_INSTANCE_TYPE

  echo "Node Group has been successfully created."
}


echo "Select an operation:"
echo "0. Create VPC and Subnets"
echo "1. Create Cluster Role"
echo "2. Create Node Role"
echo "3. Create EKS Cluster"
echo "4. Create Node Group"
echo "5. All"

read -p "Enter your choice [0-5]: " choice


case $choice in
    0)
        create_vpc_and_subnets
        ;;
    1)
        create_cluster_role
        ;;
    2)
        create_node_role
        ;;
    3)
        create_eks_cluster
        ;;
    4)
        create_node_group
        ;;
    5)
        create_vpc_and_subnets
        create_cluster_role
        create_node_role
        create_eks_cluster
        create_node_group
        ;;
    *)
        echo "Invalid choice"
        ;;
esac

echo "Operation completed."


# Get user inputs
read -p "Enter the cluster name: " CLUSTER_NAME
read -p "Enter the VPC ID: " VPC_ID
read -p "Enter the subnet IDs (comma-separated without spaces e.g., subnet-xxxxx,subnet-yyyyy): " SUBNET_IDS

echo "EKS Cluster and Node Group have been successfully created."
