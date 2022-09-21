module "aws_config" {
  source  = "lacework/config/aws"
  version = "~> 0.6"
}

module "aws_cloudtrail" {
  source  = "lacework/cloudtrail/aws"
  version = "~> 2.3"

  use_existing_cloudtrail   = false     
  use_existing_iam_role     = false
  cloudtrail_name           = "${var.environment}-lacework-trail"
}