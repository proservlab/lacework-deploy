data "aws_caller_identity" "current" {}

resource "aws_ssm_parameter" "db_host" {
    name = "db_host"
    value = aws_db_instance.database.endpoint
    type = "String"
}

resource "aws_ssm_parameter" "db_name" {
    name = "db_name"
    value = var.database_name
    type = "String"
}

resource "aws_ssm_parameter" "db_username" {
    name = "db_username"
    value = var.root_db_username
    type = "SecureString"
    key_id = aws_kms_key.this.id
}

resource "aws_ssm_parameter" "db_password" {
    name = "db_password"
    value = var.root_db_username
    type = "SecureString"
    key_id = aws_kms_key.this.id
}

resource "aws_kms_key" "this" {
    description = "For encrypting and decrypting db-related parameters"
    deletion_window_in_days = 7
    policy =    <<-EOF
                {
                "Version": "2012-10-17",
                "Statement": [
                    {
                    "Sid": "Allow access for Account Holder",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "${data.aws_caller_identity.current.arn}"
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
                            "kms:Decrypt"
                        ],
                        "Effect": "Allow",
                        "Principal": {
                            "AWS": [
                                "arn:aws:iam:::${data.aws_caller_identity.current.account_id}:role/${var.ec2_instance_role_name}"
                            ]
                        }
                    }
                ]
                }
                EOF
}

resource "aws_iam_policy" "db_get_parameters" {
    name = "db_get_parameters"
    policy =    <<-EOF
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Action": [
                                "ssm:GetParameters"
                            ],
                            "Resource": [
                                "${aws_ssm_parameter.db_host.arn}",
                                "${aws_ssm_parameter.db_name.arn}",
                                "${aws_ssm_parameter.db_username.arn}",
                                "${aws_ssm_parameter.db_password.arn}"
                            ]
                        },
                        {
                            "Effect": "Allow",
                            "Action": [
                                "kms:Decrypt"
                            ],
                            "Resource": [
                                "${aws_kms_key.this.arn}"
                            ]
                        }
                    ]
                }
                EOF
}

resource "aws_iam_role_policy_attachment" "ec2-instance-policy" {
  role       = var.ec2_instance_role_name
  policy_arn = aws_iam_policy.db_get_parameters.arn
}

