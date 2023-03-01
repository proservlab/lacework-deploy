# project level integration
# module "lacework_gcp_agentless_scanning_project_single_region" {
#   source = "lacework/agentless-scanning/gcp"
#   version = "~> 0.1"

#   project_filter_list = [
#     var.gcp_project_id
#   ]

#   global                    = true
#   regional                  = true
#   lacework_integration_name = "agentless_from_terraform"
# }

data "google_project" "project" {}

# org level integration
module "lacework_gcp_agentless_scanning_org_multi_region" {
  source  = "lacework/agentless-scanning/gcp"
  version = "~> 0.1"

  project_filter_list = [
    var.gcp_project_id
  ]

  integration_type = "ORGANIZATION"
  organization_id  = "data.google_project.project.org_id"

  global                    = true
  regional                  = true
  lacework_integration_name = "agentless_from_terraform"
}

module "lacework_gcp_agentless_scanning_org_multi_region_usc1" {
  source  = "lacework/agentless-scanning/gcp"
  version = "~> 0.1"

  regional                = true
  global_module_reference = module.lacework_gcp_agentless_scanning_org_multi_region
}
