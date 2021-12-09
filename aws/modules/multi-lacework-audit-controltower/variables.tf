variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "environment" {
    type    = string
}

variable "sns_topic_arn" {
  type        = string
  description = "The SNS topic ARN. Usually in the form of: arn:aws:sns:<control-tower-region>:<aws_audit_account_id>:aws-controltower-AllConfigNotifications"
}

variable "s3_bucket_arn" {
  type = string
  description = "The ARN for the  S3 bucket for consolidated CloudTrail logging. Usually in the form like: arn:aws:s3:::aws-controltower-logs-<log_archive_account_id>-<control_tower_region>"
}

variable "org_account_mappings" {
  type = list(object({
    default_lacework_account = string
    mapping = list(object({
      lacework_account = string
      aws_accounts     = list(string)
    }))
  }))
  default     = []
  description = "Mapping of AWS accounts to Lacework accounts within a Lacework organization"
}