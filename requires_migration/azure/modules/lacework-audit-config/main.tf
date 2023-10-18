module "az_ad_application" {
  source  = "lacework/ad-application/azure"
  version = "~> 1.3"
}

# module "az_config" {
#   source  = "lacework/config/azure"
#   version = "~> 1.1"

#   use_existing_ad_application = true
#   all_subscriptions = true
#   application_id              = module.az_ad_application.application_id
#   application_password        = module.az_ad_application.application_password
#   service_principal_id        = module.az_ad_application.service_principal_id
# }

module "az_config" {
  source  = "../lacework-config-manual"

  use_existing_ad_application = true
  all_subscriptions           = true
  application_id              = module.az_ad_application.application_id
  application_password        = module.az_ad_application.application_password
  service_principal_id        = module.az_ad_application.service_principal_id
}

module "az_activity_log" {
  source  = "../lacework-audit-manual"

  use_existing_ad_application = true
  all_subscriptions = true
  application_id              = module.az_ad_application.application_id
  application_password        = module.az_ad_application.application_password
  service_principal_id        = module.az_ad_application.service_principal_id
}