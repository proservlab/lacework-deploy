###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/listener-port-forward"
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
    source          = "../../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = module.payload.outputs["base64_payload"]
}