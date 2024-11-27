###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/deploy-log4j-app"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        listen_port     = var.listen_port
        trusted_addresses = var.trusted_addresses
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