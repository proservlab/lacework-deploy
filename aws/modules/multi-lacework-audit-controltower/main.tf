terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.12.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

# resource "lacework_integration_aws_ct" "consolidated" {
#   alias     = lacework.organization
#   name      = "Consolidated CloudTrail"
#   queue_url = "https://sqs.us-west-2.amazonaws.com/123456789012/my_queue"
#   credentials {
#     role_arn    = "arn:aws:iam::1234567890:role/lacework_iam_example_role"
#     external_id = "12345"
#   }

#   org_account_mappings {
#     default_lacework_account = "lw_account_1"

#     mapping {
#       lacework_account = "lw_account_2"
#       aws_accounts     = ["234556677", "774564564"]
#     }

#     mapping {
#       lacework_account = "lw_account_3"
#       aws_accounts     = ["553453453", "934534535"]
#     }
#   }
# }

module "control_tower_integration_setup" {
  source  = "lacework/cloudtrail-controltower/aws"
  version = "~> 0.1"
  providers = {
    aws.audit = aws.audit
    aws.log_archive = aws.log
  }
  # SNS Topic ARN is usually in the form: arn:aws:sns:<control_tower_region>:<aws_audit_account_id>:aws-controltower-AllConfigNotifications
  sns_topic_arn   = "arn:aws:sns:us-east-1:986224395668:aws-controltower-AllConfigNotifications"
  # S3 Bucket ARN is usually in the form: arn:aws:s3:::aws-controltower-logs-<log_archive_account_id>-<control_tower_region>
  s3_bucket_arn = "arn:aws:s3:::aws-controltower-logs-538045531862-us-east-1"
}