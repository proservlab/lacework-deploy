###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/deploy-git"
    inputs = {
        environment                 = var.environment
        deployment                  = var.deployment
        
        tag                         = var.tag
        
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