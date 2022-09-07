provider "lacework" {
  profile="snifftest-stitch"
}

provider "aws" {
  profile = "proservlab"
  region = "us-east-1"
}

# provider "aws" {
#   profile = "proservlab"
#   alias  = "usw2"
#   region = "us-west-2"
# }

module "lacework_aws_agentless_scanning_global" {
  source  = "lacework/agentless-scanning/aws"
  version = ">= 0.3.2"

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