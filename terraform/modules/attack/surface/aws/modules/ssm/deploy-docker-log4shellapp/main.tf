###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/deploy-docker-log4shellapp"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        timeout         = var.timeout
        cron            = var.cron
        listen_port     = var.listen_port
    }
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = module.payload.outputs["base64_payload"]
}