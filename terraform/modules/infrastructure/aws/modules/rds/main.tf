data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

resource "random_string" "root_db_password" {
    length            = 16
    special           = false
    upper             = true
    lower             = true
    numeric           = true
}

locals {
  init_db_username = var.root_db_username
  init_db_password = random_string.root_db_password.result
  
  database_name = var.database_name
  database_port = var.database_port

  subnets_cidrs = [
      cidrsubnet(var.vpc_subnet,8,200),
      cidrsubnet(var.vpc_subnet,8,201)
  ]

  availability_zones = [
      data.aws_availability_zones.available.names[0],
      data.aws_availability_zones.available.names[1]
  ]
  

}

resource "aws_route_table" "database" {
    vpc_id = var.vpc_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.igw_id
    }

    tags = {
        Name = "ec2db-internet-gw-route-${var.environment}-${var.deployment}"
        deployment = var.deployment
        environment = var.environment
    }
}

resource "aws_route_table_association" "database" {
  count = length(local.subnets_cidrs)
  subnet_id = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

resource "aws_subnet" "database" {
  vpc_id                  = var.vpc_id
  count                   = length(local.subnets_cidrs)
  cidr_block              = element(local.subnets_cidrs, count.index)
  availability_zone       = element(local.availability_zones, count.index)

  tags = {
    Name        = "db-subnet-${var.environment}-${var.deployment}-${element(local.availability_zones, count.index)}"
    environment = var.environment
    deployment = var.deployment
  }
}

resource "aws_db_subnet_group" "database" {
  description = "db subnet group"
  name        = "db_subnet_group_${var.environment}_${var.deployment}"
  subnet_ids  = aws_subnet.database.*.id

  tags = {
    Name = "db-subnet-group-${var.environment}-${var.deployment}"
  }
}

resource "aws_security_group" "database" {
  name = "db-sg-${var.environment}-${var.deployment}"

  description = "db security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.database_port
    to_port     = var.database_port
    protocol    = "tcp"
    description = "db mysql"
    security_groups = [var.trusted_sg_id]
  }

  # Allow outbound traffic to private subnets.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [var.trusted_sg_id]
  }
}

resource "aws_db_instance" "database" {
  allocated_storage                     = 5
  max_allocated_storage                 = 10
  db_name                               = "mydb"
  port                                  = local.database_port
  engine                                = "mysql"
  engine_version                        = "5.7"
  instance_class                        = "db.t3.micro"
  username                              = local.init_db_username
  password                              = local.init_db_password
  identifier                            = "ec2rds-${var.environment}-${var.deployment}"
  iam_database_authentication_enabled   = true
  parameter_group_name                  = "default.mysql5.7"
  skip_final_snapshot                   = true
  
  db_subnet_group_name                  = aws_db_subnet_group.database.id
  vpc_security_group_ids = [
    aws_security_group.database.id,
  ]

  tags = {
    Name = "db-${var.environment}-${var.deployment}",
    environment = var.environment
    deployment = var.deployment
  }
}

# Create the S3 bucket - with private acl
resource "aws_s3_bucket" "bucket" {
  bucket = "db-backup-${var.environment}-${var.deployment}"
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket]

  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

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
          "s3:GetBucketLocation",
        ],
        Resource = [
          "arn:aws:s3:::db-backup-${var.environment}-${var.deployment}",
          "arn:aws:s3:::db-backup-${var.environment}-${var.deployment}/*",
        ],
      },
    ],
  })
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

resource "aws_ssm_parameter" "db_host" {
    name = "db_host"
    value = aws_db_instance.database.endpoint
    type = "String"
}

resource "aws_ssm_parameter" "db_port" {
    name = "db_port"
    value = local.database_port
    type = "String"
}

resource "aws_ssm_parameter" "db_name" {
    name = "db_name"
    value = var.database_name
    type = "String"
}

resource "aws_ssm_parameter" "db_username" {
    name = "db_username"
    value = local.init_db_username
    type = "SecureString"
    key_id = aws_kms_key.this.id
}

resource "aws_ssm_parameter" "db_password" {
    name = "db_password"
    value = local.init_db_password
    type = "SecureString"
    key_id = aws_kms_key.this.id
}

resource "aws_ssm_parameter" "db_region" {
    name = "db_region"
    value = var.region
    type = "String"
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
                                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.ec2_instance_role_name}"
                            ]
                        },
                        "Resource": "*"
                    }
                ]
                }
                EOF
    tags = {
        Name        = "db-kms-key-${var.environment}-${var.deployment}"
        environment = var.environment
        deployment = var.deployment
    }
}

resource "aws_iam_policy" "db_get_parameters" {
    name = "db_access_${var.environment}_${var.deployment}"
    policy =    <<-EOF
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Sid": "GetDBParams",
                            "Effect": "Allow",
                            "Action": [
                                "ssm:GetParameters"
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
                            "Sid": "KMSListKeys",
                            "Effect": "Allow",
                            "Action": [
                                "kms:ListKeys",
                                "kms:ListResourceTags"
                            ],
                            "Resource": "*"
                        },
                        {
                            "Sid": "KMSDecryptKey",
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
                            "Sid": "AllowAnySnapshotName",
                            "Effect": "Allow",
                            "Action": [
                                "rds:CreateDBSnapshot",
                                "rds:ExportSnapshot",
                                "rds:AddTagsToResource"
                            ],
                            "Resource": [
                                "arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:snapshot:*"
                            ]
                        },
                        {
                            "Sid":"AllowCreateSnapshot",
                            "Effect":"Allow",
                            "Action":[
                                "rds:CreateDBSnapshot"
                            ],
                            "Resource":"${aws_db_instance.database.arn}"
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
                            "Sid": "RDSConnect",
                            "Effect": "Allow",
                            "Action": [
                                "rds-db:connect"
                            ],
                            "Resource": [
                                "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.database.resource_id}/*"
                            ]
                        },
                        {
                            "Effect": "Allow",
                            "Action": [
                                "iam:ListRole",
                                "iam:GetRole",
                                "iam:PassRole"
                            ],
                            "Resource": "${aws_iam_role.rds_export_role.arn}"
                        }
                    ]
                }
                EOF
}

resource "aws_iam_role_policy_attachment" "ec2-db-policy" {
  role       = var.ec2_instance_role_name
  policy_arn = aws_iam_policy.db_get_parameters.arn
}