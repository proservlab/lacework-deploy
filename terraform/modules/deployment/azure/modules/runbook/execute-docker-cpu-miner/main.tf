###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/execute-docker-cpu-miner"
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
# RUNBOOK
#####################################################

module "runbook" {
    source = "../base"
    environment                 = var.environment
    deployment                  = var.deployment
    region                      = var.region
    
    resource_group              = var.resource_group
    automation_account          = var.automation_account
    automation_princial_id      = var.automation_princial_id
    tag                         = var.tag
        
    base64_payload              = module.payload.outputs["base64_payload"]
}