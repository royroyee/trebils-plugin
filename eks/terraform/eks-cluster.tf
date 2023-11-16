locals {
  common_tags = {
    Project     = "multi-cloud"
    Environment = "test"
  }
}

resource "aws_iam_role" "eks_cluster" {
  name = var.cluster_name

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_cluster.name
}

# Cluster security group
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.eks_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "eks-node-group"
    },
    local.common_tags
  )
}

# Allow worker nodes to communicate with the cluster
resource "aws_security_group_rule" "eks_cluster_ingress_from_nodes" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_cluster_sg.id
  type              = "ingress"
  source_security_group_id = aws_security_group.eks_node_sg.id
}

# EKS cluster resource
resource "aws_eks_cluster" "demo" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version = "1.27"

  vpc_config {
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    subnet_ids         = aws_subnet.eks_subnet[*].id
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policies]
}

data "aws_availability_zones" "available" {
  filter {
    name   = "zone-name"
    values = ["ap-northeast-2a", "ap-northeast-2b"]
  }
}