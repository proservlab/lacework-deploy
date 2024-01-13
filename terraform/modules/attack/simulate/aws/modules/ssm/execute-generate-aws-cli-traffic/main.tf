###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/execute-generate-aws-cli-traffic"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        timeout         = var.timeout
        cron            = var.cron
        compromised_credentials = var.compromised_credentials
        compromised_keys_user   = var.compromised_keys_user
        profile                 = var.profile
        commands                = var.commands
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