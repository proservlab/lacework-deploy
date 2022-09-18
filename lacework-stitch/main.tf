module "aws_config" {
  source  = "lacework/config/aws"
  version = "~> 0.6"
}

module "aws_cloudtrail" {
  source  = "lacework/cloudtrail/aws"
  version = "~> 2.3"

  use_existing_cloudtrail   = false     
  use_existing_iam_role     = true
  iam_role_name             = module.aws_config.iam_role_name
  iam_role_arn              = module.aws_config.iam_role_arn
  iam_role_external_id      = module.aws_config.external_id
}

provider "lacework" {
  profile="snifftest-stitch"
}

provider "aws" {
  profile = "proservlab"
  region = "us-east-1"
}

module "lacework_aws_agentless_scanning_global" {
  source  = "lacework/agentless-scanning/aws"
  version = ">= 0.3"

  global                    = true
  lacework_integration_name = "sidekick_from_terraform"
}

// Create regional resources in our first region
module "lacework_aws_agentless_scanning_region" {
  source  = "lacework/agentless-scanning/aws"
  version = ">= 0.3.2"

  regional                              = true
  agentless_scan_ecs_task_role_arn      = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_task_role_arn
  agentless_scan_ecs_execution_role_arn = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_execution_role_arn
  agentless_scan_ecs_event_role_arn     = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_event_role_arn
  agentless_scan_secret_arn             = module.lacework_aws_agentless_scanning_global.agentless_scan_secret_arn
  lacework_account                      = module.lacework_aws_agentless_scanning_global.lacework_account
  prefix                                = module.lacework_aws_agentless_scanning_global.prefix
  suffix                                = module.lacework_aws_agentless_scanning_global.suffix
}

// Create regional resources in our second region
# module "lacework_aws_agentless_scanning_region_usw2" {
#   source  = "lacework/agentless-scanning/aws"
#   version = ">= 0.3.2"

#   providers = {
#     aws = aws.usw2
#   }

#   regional                              = true
#   agentless_scan_ecs_task_role_arn      = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_task_role_arn
#   agentless_scan_ecs_execution_role_arn = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_execution_role_arn
#   agentless_scan_ecs_event_role_arn     = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_event_role_arn
#   agentless_scan_secret_arn             = module.lacework_aws_agentless_scanning_global.agentless_scan_secret_arn
#   lacework_account                      = module.lacework_aws_agentless_scanning_global.lacework_account
#   prefix                                = module.lacework_aws_agentless_scanning_global.prefix
#   suffix                                = module.lacework_aws_agentless_scanning_global.suffix
# }