# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table

locals {
  cluster_tags = { for cluster_name in var.clusters : "kubernetes.io/cluster/${cluster_name}" => "shared" }
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = merge(
    {
      "Name" = var.vpc_name
    },
    local.cluster_tags
  )
}

resource "aws_subnet" "eks_subnet" {
  count = length(data.aws_availability_zones.available.names)

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.eks_vpc.id

  tags = merge(
    {
      "Name"                 = "${var.subnet_name}-${count.index}",
      "kubernetes.io/role/elb" = "1"
    },
    local.cluster_tags
  )
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = { Name = var.internet_gateway_name }
}

resource "aws_route_table" "eks_rtb" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
}

resource "aws_route_table_association" "eks_rtb_assoc" {
  count = length(data.aws_availability_zones.available.names)

  subnet_id      = aws_subnet.eks_subnet[count.index].id
  route_table_id = aws_route_table.eks_rtb.id
}
