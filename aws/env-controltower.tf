locals {
  prod_environment_name = "prod"
}

module "lacework-audit" {
  source      = "./modules/multi-lacework-audit"
  environment = local.prod_environment_name
  providers = {
    aws.audit       = aws.prod
    aws.log_archive = aws.log
    lacework        = lacework.org
  }
  
  s3_bucket_arn = "arn:aws:s3:::aws-controltower-logs-538045531862-us-east-1"
  sns_topic_arn = "arn:aws:sns:us-east-1:986224395668:aws-controltower-AllConfigNotifications"

  org_account_mappings = {
    default_lacework_account = "lwps"

    mapping {
      lacework_account = "lwps-prod"
      aws_accounts     = ["837437350477"]
    }

    mapping {
      lacework_account = "lwps-stage"
      aws_accounts     = ["466038157367"]
    }

    mapping {
      lacework_account = "lwps-test"
      aws_accounts     = ["997124715511"]
    }
  }
}

