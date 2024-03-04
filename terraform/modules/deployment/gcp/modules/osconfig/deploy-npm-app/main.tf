###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/deploy-npm-app"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        tag               = var.tag
        listen_port       = var.listen_port
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