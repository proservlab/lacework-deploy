###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/listener-port-forward"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        tag               = var.tag
        host_ip         = var.host_ip
        port_forwards   = var.port_forwards
        host_ip         = var.host_ip
        host_port       = var.host_port
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