locals {
  default_tags = {
    Provisioner = "Terraform"
    Environment = "Testing"
  }
}

resource "aws_eks_cluster" "istio_service_mesh_primary_1" {
  name     = "cluster1"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids          = aws_subnet.eks_subnet[*].id
    public_access_cidrs = ["0.0.0.0/0"]
    security_group_ids = [
      aws_security_group.cluster_sg.id,
      aws_security_group.cp_sg.id
    ]
  }
  version = "1.27"

  timeouts {
    create = "20m"
  }
  depends_on = [
    aws_iam_role.eks_iam_role,
    aws_iam_role.eks_iam_node_role,
    aws_security_group.cluster_sg,
    aws_security_group.cp_sg,
    aws_security_group.wrkr_node
  ]
}

resource "aws_eks_cluster" "istio_service_mesh_primary_2" {
  name     = "cluster2"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids          = aws_subnet.eks_subnet[*].id
    public_access_cidrs = ["0.0.0.0/0"]
    security_group_ids = [
      aws_security_group.cluster_sg.id,
      aws_security_group.cp_sg.id
    ]
  }
  version = "1.27"

  timeouts {
    create = "20m"
  }
  tags = local.default_tags
  depends_on = [
    aws_iam_role.eks_iam_role,
    aws_iam_role.eks_iam_node_role,
    aws_iam_policy_attachment.eksClusterPolicyAttachmentDefault,
    aws_security_group.cluster_sg,
    aws_security_group.cp_sg,
    aws_security_group.wrkr_node
  ]
}


resource "aws_eks_addon" "eks_addon_vpc-cni" {
  cluster_name = aws_eks_cluster.istio_service_mesh_primary_1.name
  addon_name   = "vpc-cni"
  depends_on = [
    aws_iam_role.eks_iam_role,
    aws_iam_role.eks_iam_node_role,
    aws_security_group.cluster_sg,
    aws_security_group.cp_sg,
    aws_security_group.wrkr_node,
    aws_eks_cluster.istio_service_mesh_primary_1
  ]
}

resource "aws_eks_addon" "eks_addon_vpc-cni_2" {
  cluster_name = aws_eks_cluster.istio_service_mesh_primary_2.name
  addon_name   = "vpc-cni"
  depends_on = [
    aws_iam_role.eks_iam_role,
    aws_iam_role.eks_iam_node_role,
    aws_security_group.cluster_sg,
    aws_security_group.cp_sg,
    aws_security_group.wrkr_node,
    aws_eks_cluster.istio_service_mesh_primary_2
  ]
}

resource "aws_eks_node_group" "istio_service_mesh_primary_worker_group_1" {
  cluster_name    = aws_eks_cluster.istio_service_mesh_primary_1.name
  node_group_name = "istio-service-mesh-primary-worker-group-1"
  node_role_arn   = aws_iam_role.eks_iam_node_role.arn
  subnet_ids      = aws_subnet.eks_subnet[*].id

  remote_access {
  #  ec2_ssh_key               = var.ssh_key
    source_security_group_ids = [aws_security_group.wrkr_node.id]
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }
  instance_types = ["t3.medium"]

  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role.eks_iam_role,
    aws_iam_role.eks_iam_node_role,
    aws_security_group.cluster_sg,
    aws_security_group.cp_sg,
    aws_security_group.wrkr_node,
    aws_eks_cluster.istio_service_mesh_primary_1,
    aws_eks_addon.eks_addon_vpc-cni
  ]

  timeouts {
    create = "20m"
  }
  tags = local.default_tags

}


resource "aws_eks_node_group" "istio_service_mesh_primary_worker_group_2" {
  cluster_name    = aws_eks_cluster.istio_service_mesh_primary_2.name
  node_group_name = "istio-service-mesh-primary-worker-group-2"
  node_role_arn   = aws_iam_role.eks_iam_node_role.arn
  subnet_ids      = aws_subnet.eks_subnet[*].id
  remote_access {
  #  ec2_ssh_key               = var.ssh_key
    source_security_group_ids = [aws_security_group.wrkr_node.id]
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }
  instance_types = ["t3.medium"]
  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_eks_cluster.istio_service_mesh_primary_2
  ]

  timeouts {
    create = "20m"
  }
  tags = local.default_tags
}
