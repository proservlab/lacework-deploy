data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
    kubeconfig_path = pathexpand("~/.kube/aws-${var.environment}-${var.deployment}-kubeconfig")
}

module "eks-kubeconfig" {
  source = "../eks-kubeconfig"

  environment = var.environment
  deployment = var.deployment
  aws_profile_name = var.aws_profile_name
  region = var.region
  cluster_name = aws_eks_cluster.cluster.id
  kubeconfig_path = local.kubeconfig_path

  depends_on = [ 
    aws_eks_cluster.cluster,
    aws_eks_node_group.cluster
  ]
}