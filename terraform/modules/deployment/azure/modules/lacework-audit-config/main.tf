data "azurerm_subscription" "current" {
}

module "az_ad_application" {
  source  = "lacework/ad-application/azure"
  version = "~> 1.3.0"
}

module "az_config" {
  source  = "lacework/config/azure"
  version = "~> 2.0.2"

  use_existing_ad_application = true
  subscription_ids = [
    data.azurerm_subscription.current.subscription_id
  ]

  application_id              = module.az_ad_application.application_id
  application_password        = module.az_ad_application.application_password
  service_principal_id        = module.az_ad_application.service_principal_id
}

module "activity-log" {
  source  = "lacework/activity-log/azure"
  version = "~> 2.2.3"

  use_existing_ad_application = true
  
  subscription_ids = [
    data.azurerm_subscription.current.subscription_id
  ]
  application_id              = module.az_ad_application.application_id
  application_password        = module.az_ad_application.application_password
  service_principal_id        = module.az_ad_application.service_principal_id
}