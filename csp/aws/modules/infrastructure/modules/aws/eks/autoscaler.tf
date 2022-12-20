module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 4.0"
  create_role                   = true
  role_name                     = "cluster-${var.environment}-autoscaler"
  provider_url                  = replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler-aws-cluster-autoscaler"]

  tags = {
    Owner = split("/", data.aws_caller_identity.current.arn)[1]
    AutoTag_Creator = data.aws_caller_identity.current.arn
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-${var.environment}-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${aws_eks_cluster.cluster.id}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid       = "clusterAutoscalerAll"
    effect    = "Allow"

    actions   = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid        = "clusterAutoscalerOwn"
    effect     = "Allow"

    actions    = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources  = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.cluster.id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "helm_release" "cluster-autoscaler" {
  name        = "cluster-${var.environment}-autoscaler"
  
  namespace   = "kube-system"
  repository  = "stable"
  chart       = "cluster-autoscaler"
  force_update = true

  set{
    name  = "cloudProvider"
    value = "aws"
  }

  set{
    name  = "awsRegion"
    value = var.region
  }

  set{
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.cluster.id
  }

  set{
    name  = "rbac.create"
    value = true
  }

  set {
    name  = "rbac.serviceAccountAnnotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_admin.iam_role_arn
  }

  # set {
  #     name = "podAnnotations.iam\\.amazonaws\\.com\\/role"
  #     value = "arn:aws:iam::{{ terraform.kubernetes.aws.account_id }}:role\\/${var.short-region}-${var.environment}-eks-${var.cluster-id}-cluster-autoscaler"
  # }

  set {
    name = "sslCertPath"
    value = "/etc/ssl/certs/ca-bundle.crt"
  }
}