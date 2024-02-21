###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/execute-docker-nmap"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        region          = var.region
        attack_delay    = var.attack_delay
        image           = var.image
        container_name  = var.container_name
        use_tor         = var.use_tor
        ports           = var.ports
        targets         = var.targets
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