###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/deploy-lacework-agent"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        tag               = var.tag
        lacework_agent_tags         = var.lacework_agent_tags
        lacework_agent_temp_path    = var.lacework_agent_temp_path
        lacework_agent_access_token = var.lacework_agent_access_token
        lacework_server_url         = var.lacework_server_url
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