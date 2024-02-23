###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/execute-docker-composite-host-cryptomining"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        region            = var.gcp_location
        tag               = var.tag
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

#####################################################
# GCP OSCONFIG
#####################################################

module "osconfig" {
  source            = "../../../../../../common/gcp/osconfig/base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.tag
  base64_payload    = module.payload.outputs["base64_payload"]
}