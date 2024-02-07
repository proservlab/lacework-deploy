###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/execute-generate-web-traffic"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        region            = var.region
        tag               = var.tag
        delay           = var.delay
        urls            = var.urls
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