module "aws_config" {
  source  = "lacework/config/aws"
  version = "~> 0.9.0"
}

module "aws_cloudtrail" {
  source  = "lacework/cloudtrail/aws"
  version = "~> 2.7.0"

  cloudtrail_name             = var.cloudtrail_name
  use_existing_cloudtrail     = var.use_existing_cloudtrail

  use_existing_iam_role       = true
  iam_role_name               = module.aws_config.iam_role_name
  iam_role_arn                = module.aws_config.iam_role_arn
  iam_role_external_id        = module.aws_config.external_id
  
  enable_log_file_validation  = true
  bucket_force_destroy        = var.use_existing_cloudtrail == true ? false : true
  bucket_encryption_enabled   = true
  bucket_logs_enabled         = true
  bucket_versioning_enabled   = true

  external_id_length         = 1000
  
  wait_time = "120s"
}