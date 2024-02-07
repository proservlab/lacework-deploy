###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/execute-docker-hydra"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        region          = var.region
        attack_delay                        = var.attack_delay
        payload                             = var.payload
        image                               = var.image
        use_tor                             = var.use_tor
        custom_user_list                    = var.custom_user_list
        custom_password_list                = var.custom_password_list
        user_list                           = var.user_list
        password_list                       = var.password_list
        targets                             = var.targets
        ssh_user                            = var.ssh_user
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