###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/listener-http-listener"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        tag               = var.tag
        listen_ip       = var.listen_ip
        listen_port     = var.listen_port
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