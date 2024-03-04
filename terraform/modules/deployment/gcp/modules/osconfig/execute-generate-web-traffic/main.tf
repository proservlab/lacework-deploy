###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/execute-generate-web-traffic"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        region            = var.gcp_location
        tag               = var.tag
        delay           = var.delay
        urls            = var.urls
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