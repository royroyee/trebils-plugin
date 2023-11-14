variable "aws_region" {
  default = "ap-northeast-2"
}


# EKS variable
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}


variable "node_name" {
  description = "The name of the EKS cluster node"
  type        = string
  default     = "eks-node"
}

variable "vpc_name" {
  description = "The name of the EKS VPC"
  type = string
  default = "eks-vpc"
}

variable "subnet_name" {
  description = "The name of the EKS Subnet"
  type = string
  default = "eks-subnet"
}

variable "internet_gateway_name" {
  description = "The name of the EKS Internet Gateway"
  type = string
  default = "eks-gateway"
}

#variable "subnet_ids" {
#  description = "A list of subnet IDs for the EKS cluster"
#  type        = list(string)
#}

variable "node_group_desired_size" {
  description = "Desired size of the EKS node group."
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum size of the EKS node group."
  type        = number
  default     = 1
}

variable "node_group_min_size" {
  description = "Minimum size of the EKS node group."
  type        = number
  default     = 1
}

variable "node_instance_type" {
  type = list(string)
  default = ["t3.medium"]
}

variable "capacity_type" {
  type = string
  default = "SPOT"
}