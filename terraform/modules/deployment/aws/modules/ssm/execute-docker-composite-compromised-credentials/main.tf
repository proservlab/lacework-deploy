###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/execute-docker-composite-compromised-credentials"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        region          = var.region
        compromised_credentials         = var.compromised_credentials
        compromised_keys_user           = var.compromised_keys_user
        protonvpn_user                  = var.protonvpn_user
        protonvpn_password              = var.protonvpn_password
        protonvpn_tier                  = var.protonvpn_tier
        protonvpn_server                = var.protonvpn_server
        protonvpn_protocol              = var.protonvpn_protocol
        protonvpn_privatekey            = var.protonvpn_privatekey
        ethermine_wallet                = var.ethermine_wallet
        minergate_user                  = var.minergate_user
        nicehash_user                   = var.nicehash_user
        ethermine_wallet                = var.ethermine_wallet
        attack_delay                    = var.attack_delay
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