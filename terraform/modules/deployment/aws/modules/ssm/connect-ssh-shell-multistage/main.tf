###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/connect-ssh-shell-multistage"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        region          = var.region
        payload                 = var.payload
        attack_delay            = var.attack_delay
        user_list               = var.user_list
        password_list           = var.password_list
        task                    = var.task
        target_ip               = var.target_ip
        target_port             = var.target_port
        reverse_shell_host      = var.reverse_shell_host
        reverse_shell_port      = var.reverse_shell_port
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