###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/deploy-ssh-user"
    inputs = {
        environment                 = var.environment
        deployment                  = var.deployment
        
        tag                         = var.tag
        
        username                    = var.username
        password                    = var.password
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