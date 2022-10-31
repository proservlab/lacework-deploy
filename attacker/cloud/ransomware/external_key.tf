terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
    alias = "attacker"
    region  = "us-east-1"
    profile = "dev-test"
}

provider "aws" {
    alias = "target"
    region  = "us-east-1"
    profile = "default"
}

locals {
    region          = "us-east-1"
}

data "aws_caller_identity" "attacker" {
    provider = {
        aws = aws.attacker
    }
}

data "aws_caller_identity" "target" {
    provider = {
        aws = aws.target
    }
}

#######################
# TARGET
#######################

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
  bucket = "target-s3-bucket-${random_string.bucket_unique}"
  acl    = "private"   # or can be "public-read"
  tags = {
    Name        = "target-s3-bucket-${random_string.bucket_unique}"
  }
}

# upload sample content
resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.target.id
  key    = "files"
  acl    = "private"  # or can be "public-read"
  source = "./resources/files/sample_file.txt"
  etag = filemd5("./resources/files/sample_file.txt")
}

#######################
# ATTACKER
#######################

resource "aws_kms_external_key" "key" {
  description           = "sample import"
  policy                = data.aws_iam_policy_document.key.json
  key_material_base64   = file("./PlaintextKeyMaterial.b64")
  enabled               = true
  tags = {
    release = "terraform"
    group   = "sample"
  }

  provider = {
    aws = aws.attacker
  }
}

data "aws_iam_policy_document" "key" {
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.attacker.account_id}:root"]
    }
  }

  statement {
    sid       = "Allow global access to encrypt"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
    resources = [
      #"arn:aws:kms:${local.region}:${data.aws_caller_identity.attacker.account_id}:key/${aws_kms_external_key.key.id}",
      "*"
    ]

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }

  provider = {
    aws = aws.attacker
  }
}