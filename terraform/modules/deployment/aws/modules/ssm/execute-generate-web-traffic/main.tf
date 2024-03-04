###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/execute-generate-web-traffic"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        region          = var.region
        delay           = var.delay
        urls            = var.urls
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