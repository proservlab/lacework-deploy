// Create global resources, includes lacework cloud integration.
// This will also create regional resources too.
module "lacework_azure_agentless_scanning_subscription_us_west" {
  source = "../.."

  integration_level              = "SUBSCRIPTION"
  global                         = true
  create_log_analytics_workspace = true
  region                         = "West US"
}

module "lacework_azure_agentless_scanning_subscription_us_east" {
  source = "../.."

  integration_level              = "SUBSCRIPTION"
  global                         = false
  create_log_analytics_workspace = true
  global_module_reference        = module.lacework_azure_agentless_scanning_subscription_us_west
  region                         = "East US"
}
