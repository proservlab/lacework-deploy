module "aws_config" {
  source  = "lacework/config/aws"
  version = "~> 0.9.0"
}

module "aws_cloudtrail" {
  source  = "lacework/cloudtrail/aws"
  version = "~> 2.5.1"

  cloudtrail_name = "lacework-cloudtrail-${var.environment}-${var.deployment}"
  use_existing_iam_role       = true
  iam_role_name               = module.aws_config.iam_role_name
  iam_role_arn                = module.aws_config.iam_role_arn
  iam_role_external_id        = module.aws_config.external_id

  use_existing_cloudtrail     = false
  enable_log_file_validation  = true
  bucket_force_destroy        = true
  bucket_encryption_enabled   = true
  bucket_logs_enabled         = true
  bucket_versioning_enabled   = true

  external_id_length         = 1000
  
  wait_time = "120s"
}