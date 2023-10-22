variable "aws_region" {
  default = "ap-northeast-2"
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
