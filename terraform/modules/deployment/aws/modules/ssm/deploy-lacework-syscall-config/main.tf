###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../common/any/payload/linux/modules/deploy-lacework-syscall-config"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        syscall_config  = var.syscall_config
    }   
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = module.payload.outputs["base64_payload"]
}