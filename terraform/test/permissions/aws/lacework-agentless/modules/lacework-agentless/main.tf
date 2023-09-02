module "lacework_aws_agentless_scanning_global" {
  source  = "lacework/agentless-scanning/aws"
  version = "~> 0.9"

  global                    = true
  lacework_integration_name = "sidekick_from_terraform"
}

// Create regional resources in our first region
module "lacework_aws_agentless_scanning_region" {
  source  = "lacework/agentless-scanning/aws"
  version = "~> 0.9"

  regional                              = true
  agentless_scan_ecs_task_role_arn      = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_task_role_arn
  agentless_scan_ecs_execution_role_arn = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_execution_role_arn
  agentless_scan_ecs_event_role_arn     = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_event_role_arn
  agentless_scan_secret_arn             = module.lacework_aws_agentless_scanning_global.agentless_scan_secret_arn
  lacework_account                      = module.lacework_aws_agentless_scanning_global.lacework_account
  prefix                                = module.lacework_aws_agentless_scanning_global.prefix
  suffix                                = module.lacework_aws_agentless_scanning_global.suffix
}