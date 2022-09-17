# module "aws_config" {
#   source  = "lacework/config/aws"
#   version = "~> 0.6"
# }

# module "aws_cloudtrail" {
#   source  = "lacework/cloudtrail/aws"
#   version = "~> 2.3"

#   use_existing_cloudtrail   = false     
#   use_existing_iam_role     = true
#   #bucket_arn                = "arn:aws:s3:::aws-controltower-logs-538045531862-us-east-1/o-y3gcbsjf7l/AWSLogs/997124715511/"
#   #bucket_name               = "bucket-name"
#   #sns_topic_name             = "cloudtrail-multi-region-sns-topic"
#   iam_role_name             = module.aws_config.iam_role_name
#   iam_role_arn              = module.aws_config.iam_role_arn
#   iam_role_external_id      = module.aws_config.external_id
# }