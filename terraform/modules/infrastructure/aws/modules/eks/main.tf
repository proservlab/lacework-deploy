data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
    kubeconfig_path = pathexpand("~/.kube/aws-${var.environment}-${var.deployment}-kubeconfig")
}

module "aws-eks-kubeconfig" {
  source = "../eks-kubeconfig"
  environment = var.environment
  deployment = var.deployment
  aws_profile_name = var.aws_profile_name
  region = var.region
  cluster_name = aws_eks_cluster.cluster.id
  kubeconfig_path = var.kubeconfig_path
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [module.aws-eks-kubeconfig]

  create_duration = "60s"
}