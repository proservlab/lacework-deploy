terraform {
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

module "aws_cloudtrail" {
  source  = "lacework/cloudtrail/aws"
  version = "~> 2.1.1"

  use_existing_cloudtrail   = false     
  use_existing_iam_role     = false
  #bucket_arn                = "arn:aws:s3:::aws-controltower-logs-538045531862-us-east-1/o-y3gcbsjf7l/AWSLogs/997124715511/"
  #bucket_name               = "bucket-name"
  #sns_topic_name             = "cloudtrail-multi-region-sns-topic"
}