###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/execute-generate-gcp-cli-traffic"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        region            = var.gcp_location
        tag               = var.tag
        compromised_credentials = var.compromised_credentials
        compromised_keys_user   = var.compromised_keys_user
        commands                = var.commands
    }
}

#####################################################
# GCP OSCONFIG
#####################################################

module "osconfig" {
  source            = "../base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.tag
  base64_payload    = module.payload.outputs["base64_payload"]
}