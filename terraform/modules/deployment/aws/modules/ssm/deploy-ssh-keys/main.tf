###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/deploy-ssh-keys"
    inputs = {
        environment                 = var.environment
        deployment                  = var.deployment
        public_tag                  = var.public_tag
        private_tag                 = var.private_tag
        timeout                     = var.timeout
        cron                        = var.cron
        ssh_public_key_path         = var.ssh_public_key_path
        ssh_private_key_path        = var.ssh_private_key_path
        ssh_authorized_keys_path    = var.ssh_authorized_keys_path
    }
}

###########################
# SSM - Public
###########################

module "ssm-public" {
    source          = "../base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.public_tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = module.payload.outputs["base64_payload_public"]
}

###########################
# SSM - Private
###########################

module "ssm-private" {
    source          = "../base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.private_tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = module.payload.outputs["base64_payload_private"]
}