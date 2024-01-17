###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/connect-badip"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        gcp_project_id    = var.gcp_project_id
        gcp_location      = var.gcp_location
        region            = var.gcp_location
        tag               = var.tag
        attack_delay    = var.attack_delay
        image           = var.image
        container_name  = var.container_name
        use_tor         = var.use_tor
        ports           = var.ports
        targets         = var.targets
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