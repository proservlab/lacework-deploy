resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

module "aws_config" {
  source  = "lacework/config/aws"
  version = "~> 0.13"
  
  tags = var.tags
}

module "aws_cloudtrail" {
  # source  = "lacework/cloudtrail/aws"
  # version = "~> 2.8.0"
  source = "./cloudtrail"

  cloudtrail_name = var.cloudtrail_name
  use_existing_iam_role       = var.use_existing_iam_role
  iam_role_name               = var.iam_role_name
  iam_role_arn                = var.iam_role_arn
  iam_role_external_id        = var.iam_role_external_id

  create_lacework_integration = var.create_lacework_integration
  consolidated_trail = var.consolidated_trail
  is_organization_trail = var.is_organization_trail
  org_account_mappings = var.org_account_mappings
  use_existing_kms_key = var.use_existing_kms_key
  use_existing_iam_role_policy = var.use_existing_iam_role_policy
  permission_boundary_arn = var.permission_boundary_arn
  external_id_length = var.external_id_length
  prefix = var.prefix
  enable_log_file_validation = var.enable_log_file_validation
  bucket_name = var.bucket_name
  bucket_arn = var.bucket_arn
  bucket_encryption_enabled = var.bucket_encryption_enabled
  bucket_logs_enabled = var.bucket_logs_enabled
  bucket_enable_mfa_delete = var.bucket_enable_mfa_delete
  bucket_versioning_enabled = var.bucket_versioning_enabled
  bucket_force_destroy = var.bucket_force_destroy
  bucket_sse_algorithm = var.bucket_sse_algorithm
  bucket_sse_key_arn = var.bucket_sse_key_arn
  log_bucket_name = var.log_bucket_name
  access_log_prefix = var.access_log_prefix
  s3_notification_log_prefix = var.s3_notification_log_prefix
  s3_notification_type = var.s3_notification_type
  sns_topic_arn = var.sns_topic_arn
  sns_topic_name = var.sns_topic_name
  sns_topic_encryption_key_arn = var.sns_topic_encryption_key_arn
  sns_topic_encryption_enabled = var.sns_topic_encryption_enabled
  sqs_queue_name = var.sqs_queue_name
  sqs_encryption_enabled = var.sqs_encryption_enabled
  sqs_encryption_key_arn = var.sqs_encryption_key_arn
  use_s3_bucket_notification = var.use_s3_bucket_notification
  use_existing_cloudtrail = var.use_existing_cloudtrail
  use_existing_access_log_bucket = var.use_existing_access_log_bucket
  use_existing_sns_topic = var.use_existing_sns_topic
  cross_account_policy_name = var.cross_account_policy_name
  sqs_queues = var.sqs_queues
  lacework_integration_name = var.lacework_integration_name
  lacework_aws_account_id = var.lacework_aws_account_id
  wait_time = var.wait_time
  kms_key_rotation = var.kms_key_rotation
  kms_key_deletion_days = var.kms_key_deletion_days
  kms_key_multi_region = var.kms_key_multi_region
  enable_cloudtrail_s3_management_events = var.enable_cloudtrail_s3_management_events

  tags = var.tags

}