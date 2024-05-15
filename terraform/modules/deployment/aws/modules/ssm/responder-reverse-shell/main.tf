###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/responder-reverse-shell"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        listen_ip       = var.listen_ip
        listen_port     = var.listen_port
        payload         = var.payload
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