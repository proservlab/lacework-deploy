terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "dev-test"
}

locals {
    region          = "us-east-1"
}

data "aws_caller_identity" "current" {}

# resource "aws_kms_external_key" "key" {
#   description           = "sample import"
#   policy                = data.aws_iam_policy_document.key.json
#   key_material_base64   = file("./PlaintextKeyMaterial.b64")
#   enabled               = true
#   tags = {
#     release = "terraform"
#     group   = "sample"
#   }
# }

# data "aws_iam_policy_document" "key" {
#   statement {
#     sid       = "Enable IAM User Permissions"
#     effect    = "Allow"
#     actions   = ["kms:*"]
#     resources = ["*"]

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#     }
#   }

#   statement {
#     sid       = "Allow global access to encrypt"
#     effect    = "Allow"
#     actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
#     resources = [
#       #"arn:aws:kms:${local.region}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_external_key.key.id}",
#       "*"
#     ]

#     principals {
#       type = "AWS"
#       identifiers = [
#         "*",
#       ]
#     }
#   }
# }