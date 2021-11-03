

module "aws_config" {
  source  = "lacework/config/aws"
  version = "~> 0.1"
}

module "aws_cloudtrail" {
  source  = "lacework/cloudtrail/aws"
  version = "~> 0.1"

  use_existing_cloudtrail   = true      
  bucket_arn                = "arn:aws:s3:::proservlab-audit"
  sns_topic_name             = "cloudtrail-multi-region-sns-topic"
  use_existing_iam_role     = true
  iam_role_name             = module.aws_config.iam_role_name
  iam_role_arn              = module.aws_config.iam_role_arn
  iam_role_external_id      = module.aws_config.external_id
}