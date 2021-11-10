
module "gcp_organization_config" {
  source  = "lacework/config/gcp"
  version = "~> 1.0"

  org_integration = true
  organization_id = var.gcp_organization_id
}

module "gcp_organization_audit_log" {
  source  = "lacework/audit-log/gcp"
  version = "~> 2.0"

  bucket_force_destroy         = true
  org_integration              = true
  use_existing_service_account = false
  service_account_name         = "lacework"
  organization_id              = var.gcp_organization_id
}

# terraform {
#   required_providers {
#     lacework = {
#       source = "lacework/lacework"
#       version = "~> 0.5"
#     }
#   }
# }
# provider "google" {
#   credentials = file("account.json")
#   project     = "th-lacework-4306"
# }
# provider "lacework" {
#   alias = "GOOGLE-CLOUD"
#   subaccount =  "GOOGLE-CLOUD"
# }
# #provider "lacework" {}
# module "gcp_organization_config" {
#   source  = "lacework/config/gcp"
#   version = "~> 1.0"

#   providers = {
#     lacework = lacework.GOOGLE-CLOUD
#   }

#   org_integration = true
#   organization_id = "969366444050"
# }
# module "gcp_organization_audit_log" {
#   source  = "lacework/audit-log/gcp"
#   version = "~> 2.0"

#   providers = {
#     lacework = lacework.GOOGLE-CLOUD
#   }

#   bucket_force_destroy         = true
#   org_integration              = true
#   use_existing_service_account = true
#   service_account_name         = module.gcp_organization_config.service_account_name
#   service_account_private_key  = module.gcp_organization_config.service_account_private_key
#   organization_id              = "969366444050"
# }