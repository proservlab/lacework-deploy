########################################
# RDS Service Export Role & Policy
########################################

# Create the IAM policy for the S3 bucket
resource "aws_iam_policy" "rds_export_policy" {
  name        = "db-export-policy-${var.environment}-${var.deployment}"
  description = "Policy for DB export to S3"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            Sid    = "ExportPolicy",
            Effect = "Allow",
            Action = [
                "s3:PutObject*",
                "s3:ListBucket",
                "s3:GetObject*",
                "s3:DeleteObject*",
                "s3:GetBucketLocation"
            ],
            Resource = [
                "${aws_s3_bucket.bucket.arn}",
                "${aws_s3_bucket.bucket.arn}/*"
            ],
        },
        {
            Sid =  "KMSDecryptKey",
            Effect = "Allow",
            Action =  [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:CreateGrant",
                "kms:DescribeKey",
                "kms:RetireGrant",
                "kms:List*"
            ],
            Resource = [
                "${aws_kms_key.this.arn}"
            ]
        },
    ],
  })
}

# Create the IAM role for users to assume
resource "aws_iam_role" "user_role" {
  name = var.user_role_name

  # allow all users to assume this role at a resource level
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
        "Sid": "AllowAssumeRole"
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action": "sts:AssumeRole"
        }
    ]
  })

  # max session duration 12 hours
  max_session_duration = 43200

  tags = {
    environment = var.environment
    deployment = var.deployment
  }
}

# Create the IAM role for RDS S3 export
resource "aws_iam_role" "rds_export_role" {
  name               = "rds-s3-export-role-${var.environment}-${var.deployment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "export.rds.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.rds_export_role.name
  policy_arn = aws_iam_policy.rds_export_policy.arn
}

######################################################
# Grant db export and access to user and instance role
######################################################

resource "aws_iam_policy" "db_access" {
    name = "db_access_${var.environment}_${var.deployment}"
    policy =   jsonencode({
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Sid": "GetDBParams",
                            "Effect": "Allow",
                            "Action": [
                                "ssm:GetParameters",
                                "ssm:GetParameter"
                            ],
                            "Resource": [
                                "${aws_ssm_parameter.db_host.arn}",
                                "${aws_ssm_parameter.db_port.arn}",
                                "${aws_ssm_parameter.db_name.arn}",
                                "${aws_ssm_parameter.db_username.arn}",
                                "${aws_ssm_parameter.db_password.arn}",
                                "${aws_ssm_parameter.db_region.arn}"
                            ]
                        },
                        {
                            "Sid": "KMSDecryptKey",
                            "Effect": "Allow",
                            "Action": [
                                "kms:Decrypt",
                                "kms:DescribeKey",
                                "kms:List*"
                            ],
                            "Resource": [
                                "${aws_kms_key.this.arn}"
                            ]
                        },
                        {
                            "Sid": "RDSConnect",
                            "Effect": "Allow",
                            "Action": [
                                "rds-db:connect"
                            ],
                            "Resource": [
                                "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.database.resource_id}/*"
                            ]
                        }
                    ]
                })
}

resource "aws_iam_policy" "db_export" {
    name = "db_export_${var.environment}_${var.deployment}"
    policy =    jsonencode({
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Sid": "IAMListRoles",
                            "Effect": "Allow",
                            "Action": [
                                "iam:List*"
                            ],
                            "Resource": [
                                "*"
                            ]
                        },
                        {
                            "Sid": "IAMPassRole",
                            "Effect": "Allow",
                            "Action": [
                                "iam:GetRole",
                                "iam:PassRole"
                            ],
                            "Resource": "${aws_iam_role.rds_export_role.arn}"
                        },
                        {
                            "Sid": "KMSListKeys",
                            "Effect": "Allow",
                            "Action": [
                                "kms:List*",
                                "kms:Describe*"
                            ],
                            "Resource": [
                                "*"
                            ]
                        },
                        {
                            "Sid": "KMSExportKey",
                            "Effect": "Allow",
                            "Action": [
                                "kms:Encrypt",
                                "kms:Decrypt",
                                "kms:ReEncrypt*",
                                "kms:GenerateDataKey*",
                                "kms:CreateGrant",
                                "kms:DescribeKey",
                                "kms:RetireGrant"
                            ],
                            "Resource": [
                                "${aws_kms_key.this.arn}"
                            ]
                        },
                        {
                            "Sid": "KMSCreateGrant",
                            "Effect": "Allow",
                            "Action": [
                                "kms:CreateGrant",
                                "kms:ListGrants",
                                "kms:RevokeGrant"
                            ],
                            "Resource": "${aws_kms_key.this.arn}",
                            "Condition": {
                                "Bool": { "kms:GrantIsForAWSResource": "true" }
                            }
                        },
                        {
                            "Sid": "RDSListExportTasks",
                            "Effect": "Allow",
                            "Action": [
                                "rds:DescribeExportTasks*"
                            ],
                            "Resource": [
                                "*"
                            ]
                        },
                        {
                            "Sid": "RDSListInstances",
                            "Effect": "Allow",
                            "Action": [
                                "rds:DescribeDBInstances"
                            ],
                            "Resource": "*"
                        },
                        {
                            "Sid": "RDSSnapshot",
                            "Effect": "Allow",
                            "Action": [
                                "rds:CreateDBSnapshot",
                                "rds:DeleteDBSnapshot",
                                "rds:StartExportTask",
                                "rds:DescribeDBSnapshots",
                                "rds:DescribeDBClusterSnapshots",
                                "rds:AddTagsToResource"
                            ],
                            "Resource": [
                                "arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:snapshot:*"
                            ]
                        },
                        {
                            "Sid":"RDSCreateSnapshot",
                            "Effect":"Allow",
                            "Action":[
                                "rds:CreateDBSnapshot"
                            ],
                            "Resource":"${aws_db_instance.database.arn}"
                        }
                    ]
                })
}

resource "aws_iam_role_policy_attachment" "ec2_db_access" {
    role       = var.ec2_instance_role_name
    policy_arn = aws_iam_policy.db_access.arn
}

resource "aws_iam_role_policy_attachment" "ec2_db_export" {
    role       = var.ec2_instance_role_name
    policy_arn = aws_iam_policy.db_export.arn
}

resource "aws_iam_role_policy_attachment" "user_role_db_access" {
    role       = aws_iam_role.user_role.name
    policy_arn = aws_iam_policy.db_access.arn
}

resource "aws_iam_role_policy_attachment" "user_role_db_export" {
    role       = aws_iam_role.user_role.name
    policy_arn = aws_iam_policy.db_export.arn
}

######################################################
# Grant the db roles read access to the s3 bucket
######################################################

data "aws_iam_policy_document" "user_role_bucket_read" {
  statement {
    sid = "UserRolePermissions"
    actions = [
      "s3:PutObject",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}",
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "instance_role_bucket_read" {
  statement {
    sid = "InstanceRolePermissions"
    actions = [
      "s3:PutObject",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}",
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "user_role_bucket_read" {
    role       = aws_iam_role.user_role.name
    policy_arn = aws_iam_policy.user_role_bucket_read.arn
}

resource "aws_iam_role_policy_attachment" "instance_role_bucket_read" {
    role       = var.ec2_instance_role_name
    policy_arn = aws_iam_policy.instance_role_bucket_read.arn
}