terraform {
  backend "s3" {
    bucket         = var.terraform_backend_bucket
    key            = var.terraform_backend_key
    encrypt        = var.terraform_backend_encrypt
    dynamodb_table = var.terraform_backend_dynamodb_table
    region         = var.terraform_backend_region
    profile        = var.terraform_backend_profile
  }
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.22.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

module "environment-proservlab" {
  source      = "./modules/environment"
  environment = "proservlab"
  region      = var.region
  providers = {
    aws      = aws.proservlab
    lacework = lacework.proservlab
  }
}

# module "environment-proservlab-test" {
#   source      = "./modules/environment"
#   environment = "dev-test"
#   providers = {
#     aws      = aws.dev-test
#     lacework = lacework.proservlab
#   }
# }

# module "environment-proservlab-stage" {
#   source      = "./modules/environment"
#   environment = "dev-stage"
#   providers = {
#     aws      = aws.dev-stage
#     lacework = lacework.proservlab
#   }
# }

# module "environment-proservlab-prod" {
#   source      = "./modules/environment"
#   environment = "dev-prod"
#   providers = {
#     aws      = aws.dev-prod
#     lacework = lacework.proservlab
#   }
# }

# module "control_tower_integration_setup" {
#   source  = "lacework/cloudtrail-controltower/aws"
#   version = "~> 0.3.0"
#   providers = {
#     aws.audit       = aws.audit
#     aws.log_archive = aws.log
#     lacework        = lacework.proservlab

#     # organization provider when lacework subaccounts are being used
#     # lacework        = lacework.proservlab-organization
#   }
#   # SNS Topic ARN is usually in the form: arn:aws:sns:<control_tower_region>:<aws_audit_account_id>:aws-controltower-AllConfigNotifications
#   sns_topic_arn = "arn:aws:sns:us-east-1:986224395668:aws-controltower-AllConfigNotifications"
#   # S3 Bucket ARN is usually in the form: arn:aws:s3:::aws-controltower-logs-<log_archive_account_id>-<control_tower_region>
#   s3_bucket_arn = "arn:aws:s3:::aws-controltower-logs-538045531862-us-east-1"

#   # organization mapping
#   # org_account_mappings = [{
#   #   default_lacework_account = "proservlab"

#   #   mapping = [
#   #     {
#   #       lacework_account = "proservlab-prod"
#   #       aws_accounts     = ["837437350477"]
#   #     },
#   #     {
#   #       lacework_account = "proservlab-stage"
#   #       aws_accounts     = ["466038157367"]
#   #     },
#   #     {
#   #       lacework_account = "proservlab-test"
#   #       aws_accounts     = ["997124715511"]
#   #     }
#   #   ]
#   # }]
# }