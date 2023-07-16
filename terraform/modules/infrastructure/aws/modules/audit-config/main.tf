resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

module "aws_config" {
  source  = "lacework/config/aws"
  version = "~> 0.11.0"
  
  tags                       = {
    environment = var.environment
    deployment = var.deployment
  } 
}

module "aws_cloudtrail" {
  source  = "lacework/cloudtrail/aws"
  version = "~> 2.7.4"

  # cloudtrail_name = "lacework-cloudtrail-${var.environment}-${var.deployment}"
  use_existing_iam_role       = true
  iam_role_name               = module.aws_config.iam_role_name
  iam_role_arn                = module.aws_config.iam_role_arn
  iam_role_external_id        = module.aws_config.external_id

  prefix                      = "${var.environment}-${var.deployment}-${random_string.this.id}"

  use_existing_cloudtrail     = false
  use_existing_sns_topic      = false
  enable_cloudtrail_s3_management_events = true
  enable_log_file_validation  = true
  bucket_force_destroy        = true
  bucket_encryption_enabled   = true
  bucket_logs_enabled         = true
  bucket_versioning_enabled   = false

  tags                       = {
    environment = var.environment
    deployment = var.deployment
  } 
}