module "lacework_aws_agentless_scanning_global" {
  source  = "lacework/agentless-scanning/aws"
  version = "~> 0.12"

  global                    = true
  lacework_integration_name = "sidekick_from_terraform"
}

// Create regional resources in our first region
module "lacework_aws_agentless_scanning_region" {
  source  = "lacework/agentless-scanning/aws"
  version = "~> 0.12"

  regional                              = true
  global_module_reference = module.lacework_aws_agentless_scanning_global
}