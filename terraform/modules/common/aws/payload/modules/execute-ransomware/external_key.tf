terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  max_retries = 40

    alias = "attacker"
    region  = "us-east-1"
    profile = "attacker"
}

provider "aws" {
  max_retries = 40

    alias = "target"
    region  = "us-east-1"
    profile = "default"
}

locals {
    region          = "us-east-1"
    enable_target   = true
    enable_attacker = true
}

data "aws_caller_identity" "attacker" {
    provider = aws.attacker
}

data "aws_caller_identity" "target" {
    provider = aws.target
}

##################################################
# TARGET
##################################################

# create random identifier for our bucket
resource "random_string" "bucket_unique" {
    length            = 8
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

#create s3 bucket
resource "aws_s3_bucket" "target" {
    count = local.enable_target == true ? 1 : 0
    provider = aws.target
    bucket = "attacksurface-target-s3-bucket-${random_string.bucket_unique.result}"
    tags = {
        Name        = "attacksurface-target-s3-bucket-${random_string.bucket_unique.result}"
    }
    force_destroy = true
}

resource "aws_s3_bucket_acl" "target" {
    count = local.enable_target == true ? 1 : 0
    bucket = aws_s3_bucket.target[0].id
    acl    = "private" # or can be public-read
}

# upload sample content
resource "aws_s3_object" "object" {
    count = local.enable_target == true ? 1 : 0
    provider = aws.target
    bucket = aws_s3_bucket.target[0].id
    key    = "files/sample_file.txt"
    acl    = "private"  # or can be "public-read"
    source = "./resources/files/sample_file.txt"
    etag = filemd5("./resources/files/sample_file.txt")
}

data "aws_iam_policy_document" "s3_target_write" {
    count = local.enable_target == true ? 1 : 0
    statement {
        sid       = "AllowWriteAccessToTargetBucket"
        effect    = "Allow"
        actions   = [
            "s3:*"
        ]
        resources = [
            "arn:aws:s3:::${aws_s3_bucket.target[0].id}/*",
            "arn:aws:s3:::${aws_s3_bucket.target[0].id}"
        ]
    }

    statement {
        sid       = "AllowReadBuckets"
        effect    = "Allow"
        actions   = [
            "s3:List*",
            "s3:Get*",
            "s3:Copy*",
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid       = "AllowKMSEncrypt"
        effect    = "Allow"
        actions   = [
                        "kms:Encrypt",
                        "kms:Decrypt",
                        "kms:GenerateDataKey"
                    ]
        resources = [
            "arn:aws:kms:*"
        ]
    }
    statement {
        sid       = "AllowKMSCreateKey"
        effect    = "Allow"
        actions   = [
                        "kms:CreateKey",
                        "kms:ImportKey",
                        "kms:ImportKeyMaterial",
                        "kms:DeleteKey",
                        "kms:DeleteKeyMaterial",
                        "kms:EnableKey",
                        "kms:DisableKey",
                        "kms:ScheduleKeyDeletion",
                        "kms:PutKeyPolicy",
                        "kms:SetPolicy",
                        "kms:DeletePolicy",
                        "kms:CreateGrant",
                        "kms:DeleteIdentity",
                        "kms:DescribeIdentity",
                        "kms:KeyStatus",
                        "kms:Status",                        
                        "kms:List*",
                        "kms:Get*",
                        "kms:Describe*",
                        "tag:GetResources"
                    ]
        resources = [
            "*"
        ]
    }   
}

resource "aws_iam_policy" "s3_target_write" {
    count = local.enable_target == true ? 1 : 0
    name = "attacksurface-s3-write"
    policy = data.aws_iam_policy_document.s3_target_write[0].json
}

resource "aws_iam_role" "s3_target_write" {
    count = local.enable_target == true ? 1 : 0
    name = "attacksurface-s3-write"

    assume_role_policy = jsonencode({
            "Version": "2012-10-17",
            "Statement": [
                {
                "Action": "sts:AssumeRole",
                "Principal": {
                    "Service": "s3.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": "AllowAssumeRoleForS3"
                }
            ]
        })
}

resource "aws_iam_role_policy_attachment" "s3_target_write" {
    count = local.enable_target == true ? 1 : 0
    role       = aws_iam_role.s3_target_write[0].name
    policy_arn = aws_iam_policy.s3_target_write[0].arn
}

##################################################
# ATTACKER
##################################################

resource "aws_kms_external_key" "key" {
    count = local.enable_attacker == true ? 1 : 0
    provider = aws.attacker
    description           = "attacker key"
    policy                = data.aws_iam_policy_document.key.json
    key_material_base64   = file("./PlaintextKeyMaterial.b64")
    enabled               = true
    tags = {
        Name = "attacker key"
    }
}

data "aws_iam_policy_document" "key" {
    statement {
        sid       = "EnableIAMUserPermissions"
        effect    = "Allow"
        actions   = ["kms:*"]
        resources = ["*"]

        principals {
            type        = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_caller_identity.attacker.account_id}:root"]
        }
    }

    statement {
        sid       = "EnableGlobalKMSEncrypt"
        effect    = "Allow"
        actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
        resources = [
            "*"
        ]

        principals {
            type = "AWS"
            identifiers = [
                "*",
            ]
        }
    }
}