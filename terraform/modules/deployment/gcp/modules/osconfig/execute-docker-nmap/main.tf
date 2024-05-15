###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/execute-docker-nmap"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
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
  source            = "../base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.tag
  base64_payload    = module.payload.outputs["base64_payload"]
}