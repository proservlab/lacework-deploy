module "aws_eks_audit_log" {
  source             = "lacework/eks-audit-log/aws"
  version            = "~> 1.1"
  cloudwatch_regions = [var.region]
  cluster_names      = [var.cluster_name]
  bucket_force_destroy = true
  bucket_encryption_enabled = true
}