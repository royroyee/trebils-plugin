resource "aws_iam_role" "eks-node" {
  name = var.node_name

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_policies" {
  for_each = {
    "WorkerNodePolicy"            = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "CNI_Policy"                  = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "ContainerRegistryReadOnly"  = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  policy_arn = each.value
  role       = aws_iam_role.eks-node.name
}

resource "aws_security_group" "eks_node_sg" {
  name        = "eks-node-sg"
  description = "Worker Node Security Group"
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

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "worker-nodes"
  node_role_arn   = aws_iam_role.eks-node.arn
  subnet_ids      = aws_subnet.eks_subnet[*].id

  instance_types = var.node_instance_type
  capacity_type = var.capacity_type

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  depends_on = [aws_iam_role_policy_attachment.eks_node_policies]

  tags = merge(
    {
      Name = "eks-node-group"
    },
    local.common_tags
  )
}