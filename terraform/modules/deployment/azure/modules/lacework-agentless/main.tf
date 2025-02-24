data "azurerm_subscription" "current" {
}

module "lacework_azure_agentless_scanning_subscription" {
  source = "./terraform-azure-agentless-scanning"

  integration_level              = "SUBSCRIPTION"
  global                         = true
  create_log_analytics_workspace = true
  region                         = var.region
  scanning_subscription_id       = data.azurerm_subscription.current.subscription_id
  tenant_id                      = data.azurerm_subscription.current.tenant_id
  subscriptions_list             = [data.azurerm_subscription.current.id]
}