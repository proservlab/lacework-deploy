###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/deploy-azure-credentials"
    inputs = {
        environment                 = var.environment
        deployment                  = var.deployment
        
        tag                         = var.tag
        
        compromised_credentials     = var.compromised_credentials
        compromised_keys_user       = var.compromised_keys_user
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