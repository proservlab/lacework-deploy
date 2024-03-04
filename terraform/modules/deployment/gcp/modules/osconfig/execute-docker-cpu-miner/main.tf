###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/execute-docker-cpu-miner"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        tag               = var.tag
        minergate_image     = var.minergate_image
        minergate_name      = var.minergate_name
        minergate_server    = var.minergate_server
        minergate_user      = var.minergate_user
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