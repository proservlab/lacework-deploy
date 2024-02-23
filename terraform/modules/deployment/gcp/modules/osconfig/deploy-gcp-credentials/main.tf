###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/deploy-gcp-credentials"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        tag               = var.tag
        compromised_credentials = var.compromised_credentials
        compromised_keys_user = var.compromised_keys_user
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