module "lacework_s3_data_export" {
  source  = "lacework/s3-data-export/aws"
  version = "1.3.3"

  lacework_data_export_rule_name        = "AWS S3 Data Export"
  lacework_data_export_rule_description = "AWS S3 Data Export"

  tags = {
    deployment = var.deployment
    environment = var.environment
  }
}

resource "random_string" "unique_suffix" {
  length  = 8
  special = false
}

resource "aws_iam_policy" "lacework_s3_data_export_read_policy" {
  count = can(length(var.read_only_iam_user_names)) || can(length(var.read_only_iam_role_names)) ? 0 : 1 
  name        = format("lacework-s3-data-export-read-policy-%s", random_string.unique_suffix.result)
  description = "Policy allowing read access to lacework data export S3 objects"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
            "s3:GetObject",
            "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = [
          "${module.lacework_s3_data_export.bucket_arn}/*",  # Read objects within the bucket
          module.lacework_s3_data_export.bucket_arn  # List bucket permission
        ]
      }
    ]
  })
}

data "aws_iam_user" "read_only_users" {
  for_each = toset(var.read_only_iam_user_names)
  user_name = each.key
}

# Attach the S3 read policy to the user
resource "aws_iam_user_policy_attachment" "lacework_user_s3_data_export_read_policy_attachment" {
  for_each = { for i in data.aws_iam_user.read_only_users: i.name => i }
  user       = each.key
  policy_arn = aws_iam_policy.lacework_s3_data_export_read_policy.arn
}

data "aws_iam_role" "read_only_roles" {
  for_each = toset(var.read_only_iam_role_names)
  name = each.key
}

# Attach the S3 read policy to the user
resource "aws_iam_role_policy_attachment" "lacework_user_s3_data_export_read_policy_attachment" {
  for_each = { for i in data.aws_iam_user.read_only_roles: i.name => i }
  user       = each.key
  policy_arn = aws_iam_policy.lacework_s3_data_export_read_policy.arn
}