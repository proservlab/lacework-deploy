###################################
# DEV BUCKET
###################################
resource "aws_s3_bucket" "dev" {
  bucket = "eks-data-dev-${var.environment}-${var.deployment}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "dev" {
  bucket = aws_s3_bucket.dev.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dev" {
  bucket = aws_s3_bucket.dev.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

###################################
# PROD BUCKET
###################################

resource "aws_s3_bucket" "prod" {
  bucket = "eks-data-prod-${var.environment}-${var.deployment}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "prod" {
  bucket = aws_s3_bucket.prod.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prod" {
  bucket = aws_s3_bucket.prod.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

###################################
# IAM ROLE AND POLICY
###################################

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

  depends_on = [  
    kubernetes_namespace.this
  ]
}

resource "aws_iam_role" "s3_access" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name               = "eks-s3-dev-role"
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
        # OVERSCOPED PERMISSIONS ALLOWING ACCESS TO DEV AND PROD
        Resource = [
          "arn:aws:s3:::eks-data-*-${var.environment}-${var.deployment}",
          "arn:aws:s3:::eks-data-*-${var.environment}-${var.deployment}/*"
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_rw_encrypt" {
  role       = aws_iam_role.s3_access.name
  policy_arn = aws_iam_policy.s3_rw_encrypt_policy.arn
}