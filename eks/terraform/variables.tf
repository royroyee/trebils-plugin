variable "aws_region" {
  default = "ap-northeast-2"
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

# EKS variable
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = null
}

variable "cluster_version" {
  description = "Cluster Version"
  type = string
  default = null
}

variable "node_name" {
  description = "The name of the EKS cluster node"
  type        = string
  default     = null
}

variable "vpc_name" {
  description = "The name of the EKS VPC"
  type = string
  default = null
}

variable "vpc_cidr" {
  description = "VPC CIDR Range"
  type = string
  default = null
}

variable "subnet_name" {
  description = "The name of the EKS Subnet"
  type = string
  default = "null"
}

variable "internet_gateway_name" {
  description = "The name of the EKS Internet Gateway"
  type = string
  default = "null"
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