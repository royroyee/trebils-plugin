locals {
  cluster_specific_tags = { for cluster_name in var.clusters : "kubernetes.io/cluster/${cluster_name}" => "owned" }
}

resource "aws_iam_role" "eks-node" {
  for_each = toset(var.clusters)

  name = "${each.value}-node"

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

locals {
  policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role_policy_attachment" "eks_node_policies" {
  count      = length(local.policies) * length(aws_iam_role.eks-node)
  policy_arn = element(local.policies, count.index % length(local.policies))
  role       = element(values(aws_iam_role.eks-node), floor(count.index / length(local.policies))).name
}

resource "aws_security_group" "eks_node_sg" {
  for_each = toset(var.clusters)

  name        = "${each.value}-node-sg"
  description = "Worker Node Security Group for ${each.value}"
  vpc_id      = aws_vpc.eks_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { "kubernetes.io/cluster/${each.value}" = "owned" })
}

resource "aws_eks_node_group" "eks_node_group" {
  for_each = toset(var.clusters)

  cluster_name    = each.value
  node_group_name = "${each.value}-worker-nodes"
  node_role_arn   = aws_iam_role.eks-node[each.value].arn
  subnet_ids      = aws_subnet.eks_subnet[*].id

  instance_types = var.node_instance_type
  capacity_type = var.capacity_type

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  depends_on = [aws_iam_role_policy_attachment.eks_node_policies]

  tags = merge(local.common_tags, { "kubernetes.io/cluster/${each.value}" = "owned" })
}