output "subnet_ids" {
  description = "The IDs of the EKS subnets."
  value       = aws_subnet.eks_subnet[*].id
}


locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks_cluster.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.demo.endpoint}
    certificate-authority-data: ${aws_eks_cluster.demo.certificate_authority[0].data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--region"
        - var.aws_region
        - "--cluster-name"
        - "${var.cluster_name}"
KUBECONFIG
}

output "config_map_aws_auth" {
  description = "The generated config map for aws-auth"
  value       = local.config_map_aws_auth
}

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file"
  value       = "~/.kube/config"
}