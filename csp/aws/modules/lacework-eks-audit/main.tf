module "aws_eks_audit_log" {
  source             = "lacework/eks-audit-log/aws"
  version            = "~> 0.2"
  cloudwatch_regions = [var.region]
  cluster_names      = var.cluster_names
}