###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/deploy-protonvpn-docker"
    inputs = {
        environment                 = var.environment
        deployment                  = var.deployment
        
        tag                         = var.tag
        
        protonvpn_user      = var.protonvpn_user
        protonvpn_password  = var.protonvpn_password
        protonvpn_tier      = var.protonvpn_tier
        protonvpn_server    = var.protonvpn_server
        protonvpn_protocol  = var.protonvpn_protocol
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