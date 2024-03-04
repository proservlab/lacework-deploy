###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/deploy-ssh-user"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        username        = var.username
        password        = var.password
    }
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = module.payload.outputs["base64_payload"]
}