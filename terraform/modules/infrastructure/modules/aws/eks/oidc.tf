data "tls_certificate" "cluster" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

}

data "aws_iam_policy_document" "example_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws-node" {
  assume_role_policy = data.aws_iam_policy_document.example_assume_role_policy.json
  name               = "aws-node-${var.environment}-${var.deployment}"
}

resource "aws_eks_identity_provider_config" "cluster" {
  cluster_name = aws_eks_cluster.cluster.name
  oidc {
    client_id                     = substr(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, -32, -1)
    identity_provider_config_name = "cluster-${var.environment}-oidc"
    issuer_url                    = "https://${aws_iam_openid_connect_provider.cluster.url}"
  }
}
