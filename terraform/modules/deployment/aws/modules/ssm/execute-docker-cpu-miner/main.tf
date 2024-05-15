###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/execute-docker-cpu-miner"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        minergate_image     = var.minergate_image
        minergate_name      = var.minergate_name
        minergate_server    = var.minergate_server
        minergate_user      = var.minergate_user
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