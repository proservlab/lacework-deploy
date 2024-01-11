###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/deploy-protonvpn-docker"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        timeout         = var.timeout
        cron            = var.cron
        protonvpn_user      = var.protonvpn_user
        protonvpn_password  = var.protonvpn_password
        protonvpn_tier      = var.protonvpn_tier
        protonvpn_server    = var.protonvpn_server
        protonvpn_protocol  = var.protonvpn_protocol
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