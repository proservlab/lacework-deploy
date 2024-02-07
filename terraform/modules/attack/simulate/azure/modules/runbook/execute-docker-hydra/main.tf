###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/execute-docker-hydra"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        region            = var.region
        tag               = var.tag
        attack_delay                        = var.attack_delay
        payload                             = var.payload
        image                               = var.image
        use_tor                             = var.use_tor
        custom_user_list                    = var.custom_user_list
        custom_password_list                = var.custom_password_list
        user_list                           = var.user_list
        password_list                       = var.password_list
        targets                             = var.targets
        ssh_user                            = var.ssh_user
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