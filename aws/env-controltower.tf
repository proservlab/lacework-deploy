locals {
  org_environment_name = "org"
}

module "control_tower_integration_setup" {
  source  = "lacework/cloudtrail-controltower/aws"
  version = "~> 0.1"
  providers = {
    aws.audit       = aws.audit
    aws.log_archive = aws.log
    lacework        = lacework.proservlab
  }
  # SNS Topic ARN is usually in the form: arn:aws:sns:<control_tower_region>:<aws_audit_account_id>:aws-controltower-AllConfigNotifications
  sns_topic_arn = "arn:aws:sns:us-east-1:986224395668:aws-controltower-AllConfigNotifications"
  # S3 Bucket ARN is usually in the form: arn:aws:s3:::aws-controltower-logs-<log_archive_account_id>-<control_tower_region>
  s3_bucket_arn = "arn:aws:s3:::aws-controltower-logs-538045531862-us-east-1"

  # organization mapping
  # org_account_mappings = [{
  #   default_lacework_account = "proservlab"

  #   mapping = [
  #     {
  #       lacework_account = "proservlab-prod"
  #       aws_accounts     = ["837437350477"]
  #     },
  #     {
  #       lacework_account = "proservlab-stage"
  #       aws_accounts     = ["466038157367"]
  #     },
  #     {
  #       lacework_account = "proservlab-test"
  #       aws_accounts     = ["997124715511"]
  #     }
  #   ]
  # }]
}
