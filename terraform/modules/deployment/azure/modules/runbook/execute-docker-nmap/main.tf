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