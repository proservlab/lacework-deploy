###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/listener-port-forward"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        host_ip         = var.host_ip
        port_forwards   = var.port_forwards
        host_ip         = var.host_ip
        host_port       = var.host_port
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