###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/ssh-user"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        gcp_project_id    = var.gcp_project_id
        gcp_location      = var.gcp_location
        tag             = var.tag
        timeout         = var.timeout
        username        = var.username
        password        = var.password
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