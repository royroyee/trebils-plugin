output "subnet_ids" {
  description = "The IDs of the EKS subnets."
  value       = aws_subnet.eks_subnet[*].id
}

locals {
  kubeconfigs = {
    for idx, cluster_name in var.clusters :
    cluster_name => {
      apiVersion = "v1",
      clusters = [
        {
          cluster = {
            server = aws_eks_cluster.eks[idx].endpoint,
            certificate_authority_data = aws_eks_cluster.eks[idx].certificate_authority[0].data
          },
          name = "kubernetes"
        }
      ],
      contexts = [
        {
          context = {
            cluster = "kubernetes",
            user = "aws"
          },
          name = "aws"
        }
      ],
      current_context = "aws",
      kind = "Config",
      preferences = {},
      users = [
        {
          name = "aws",
          user = {
            exec = {
              apiVersion = "client.authentication.k8s.io/v1beta1",
              command = "aws",
              args = [
                "eks",
                "get-token",
                "--region",
                var.aws_region,
                "--cluster-name",
                cluster_name
              ]
            }
          }
        }
      ]
    }
  }
}

output "kubeconfigs" {
  description = "Generated kubeconfigs for clusters"
  value       = local.kubeconfigs
}
