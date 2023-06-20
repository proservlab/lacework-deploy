module "aws_eks_audit_log" {
  source             = "lacework/eks-audit-log/aws"
  version            = "~> 0.4.2"
  cloudwatch_regions = [var.region]
  cluster_names      = var.cluster_names
  bucket_force_destroy = true
  bucket_encryption_enabled = true
}