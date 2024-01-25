resource "aws_s3_bucket" "this" {
  bucket = "eks-data-${var.environment}-${var.deployment}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "this" {
    bucket = aws_s3_bucket.this[0].id
    acl    = "private" # or can be public-read
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_openid_connect_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.app_namespace}:${local.service_account}"]
    }
    principals {
      identifiers = [var.cluster_openid_connect_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "s3_access_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name               = "eks-s3-role"
}

resource "aws_iam_policy" "s3_rw_encrypt_policy" {
  name        = "s3ReadWriteEncryptPolicy"
  description = "Policy for allowing read/write and encryption on S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:PutObjectAcl",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.this.name}",
          "arn:aws:s3:::${aws_s3_bucket.this.name}/*"
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_rw_encrypt" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_rw_encrypt_policy.arn
}