###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/deploy-rds-app"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        listen_port     = var.listen_port
        db_host         = var.db_host
        db_name         = var.db_name
        db_user         = var.db_user
        db_password     = var.db_password
        db_port         = var.db_port
        db_region       = var.db_region
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