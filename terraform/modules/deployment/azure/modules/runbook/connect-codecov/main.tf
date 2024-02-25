###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/connect-codecov"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        tag               = var.tag
        host_ip         = var.host_ip
        host_port       = var.host_port
        use_ssl         = var.use_ssl
        git_origin      = var.git_origin
        env_secrets     = var.env_secrets
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