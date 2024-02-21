###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../common/any/payload/linux/modules/responder-reverse-shell-multistage"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        region          = var.region
        listen_ip               = var.listen_ip
        listen_port             = var.listen_port
        payload                 = var.payload
        attack_delay            = var.attack_delay
        iam2rds_role_name       = var.iam2rds_role_name
        iam2rds_session_name    = var.iam2rds_session_name
        reverse_shell_host      = var.reverse_shell_host
        reverse_shell_port      = var.listen_port
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