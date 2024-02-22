###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/connect-badip"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        iplist_url      = var.iplist_url
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