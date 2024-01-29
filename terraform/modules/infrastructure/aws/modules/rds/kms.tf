locals {
  use_assumed_role = can(regex(".*:assumed-role/(.*)/", data.aws_caller_identity.current.arn))
  user_is_root = can(regex("arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", data.aws_caller_identity.current.arn))
  current_user_arn       = local.use_assumed_role ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${regex(".*:assumed-role/(.*)/", data.aws_caller_identity.current.arn)[0]}" : data.aws_caller_identity.current.arn
}

resource "aws_kms_key" "this" {
    description = "For encrypting and decrypting db-related parameters"
    deletion_window_in_days = 7
    policy = jsonencode({
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "Allow access for Account Holder",
                        "Effect": "Allow",
                        "Principal": {
                            "AWS": local.user_is_root ? [
                                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                            ] : [
                                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
                                "${local.current_user_arn}"
                            ]
                        },
                        "Action": [
                            "kms:Create*",
                            "kms:Describe*",
                            "kms:Enable*",
                            "kms:List*",
                            "kms:Put*",
                            "kms:Update*",
                            "kms:Revoke*",
                            "kms:Disable*",
                            "kms:Get*",
                            "kms:Delete*",
                            "kms:TagResource",
                            "kms:UntagResource",
                            "kms:ScheduleKeyDeletion",
                            "kms:CancelKeyDeletion",
                            "kms:Encrypt",
                            "kms:Decrypt",
                            "kms:ReEncrypt*",
                            "kms:GenerateDataKey*"
                        ],
                        "Resource": "*"
                    },
                    {
                        "Sid": "AllowEC2RoleDecrypt",
                        "Action": [
                            "kms:Decrypt",
                            "kms:List*",
                            "kms:Describe*"
                        ],
                        "Effect": "Allow",
                        "Principal": {
                            "AWS": [
                                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.ec2_instance_role_name}",
                                "${aws_iam_role.user_role.arn}"
                                
                            ]
                        },
                        "Resource": "*"
                    },
                    {
                        "Sid": "AllowRDSRoleDecrypt",
                        "Action": [
                            "kms:Encrypt",
                            "kms:Decrypt",
                            "kms:ReEncrypt*",
                            "kms:GenerateDataKey*",
                            "kms:CreateGrant",
                            "kms:DescribeKey",
                            "kms:RetireGrant"
                        ],
                        "Effect": "Allow",
                        "Principal": {
                            "AWS": [
                                "${aws_iam_role.rds_export_role.arn}"
                            ]
                        },
                        "Resource": "*"
                    },
                    {
                      "Sid": "Allow grants on the key",
                      "Effect": "Allow",
                      "Principal": {
                          "AWS": [ 
                            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.ec2_instance_role_name}",
                            "${aws_iam_role.user_role.arn}"
                          ]
                          
                      },
                      "Action": [
                          "kms:CreateGrant",
                          "kms:ListGrants",
                          "kms:RevokeGrant"
                      ],
                      "Resource": "*",
                      "Condition": {
                          "Bool": { "kms:GrantIsForAWSResource": "true" }
                      }
                    }
                ]
            })
    tags = {
        Name        = "db-kms-key-${var.environment}-${var.deployment}"
        environment = var.environment
        deployment = var.deployment
    }
}