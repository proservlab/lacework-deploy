###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/deploy-gcp-credentials"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        gcp_project_id    = var.gcp_project_id
        gcp_location      = var.gcp_location
        region            = var.gcp_location
        tag               = var.tag
        compromised_credentials = var.compromised_credentials
        compromised_keys_user = var.compromised_keys_user
    }
}

#####################################################
# GCP OSCONFIG
#####################################################

module "osconfig" {
  source            = "../../../../../../common/gcp/osconfig/base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.tag
  base64_payload    = module.payload.outputs["base64_payload"]
}