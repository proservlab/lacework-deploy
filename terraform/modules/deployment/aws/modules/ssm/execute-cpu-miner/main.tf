###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/execute-cpu-miner"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        minergate_server    = var.minergate_server
        minergate_user      = var.minergate_user
        xmrig_version       = var.xmrig_version
        attack_delay        = var.attack_delay
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