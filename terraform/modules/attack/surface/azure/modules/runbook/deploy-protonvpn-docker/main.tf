###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/deploy-protonvpn-docker"
    inputs = {
        environment                 = var.environment
        deployment                  = var.deployment
        region                      = var.region
        resource_group              = var.resource_group
        automation_account          = var.automation_account
        automation_princial_id      = var.automation_princial_id
        
        tag                         = var.tag
        
        protonvpn_user      = var.protonvpn_user
        protonvpn_password  = var.protonvpn_password
        protonvpn_tier      = var.protonvpn_tier
        protonvpn_server    = var.protonvpn_server
        protonvpn_protocol  = var.protonvpn_protocol
    }   
}

#####################################################
# RUNBOOK
#####################################################

module "runbook" {
    source = "../../../../../../common/azure/runbook/base"
    environment                 = var.environment
    deployment                  = var.deployment
    region                      = var.region
    
    resource_group              = var.resource_group
    automation_account          = var.automation_account
    automation_princial_id      = var.automation_princial_id
    tag                         = var.tag
        
    base64_payload              = module.payload.outputs["base64_payload"]
}