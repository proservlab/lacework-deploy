###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../common/any/payload/linux/modules/deploy-aws-credentials"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        compromised_credentials     = var.compromised_credentials
        compromised_keys_user       = var.compromised_keys_user
    }   
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = module.payload.outputs["base64_payload"]
}