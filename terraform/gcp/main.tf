##################################################
# KUBECONFIG STAGING
##################################################

locals {
  default_kubeconfig_path  = pathexpand("~/.kube/config")
  attacker_kubeconfig_path = pathexpand("~/.kube/gcp-attacker-${var.deployment}-kubeconfig")
  target_kubeconfig_path   = pathexpand("~/.kube/gcp-target-${var.deployment}-kubeconfig")

  kubeconfigs = [
    local.default_kubeconfig_path,
    local.attacker_kubeconfig_path,
    local.target_kubeconfig_path
  ]
}

# stage the kubeconfig files to avoid provider errors
resource "null_resource" "kubeconfig" {
  for_each = toset([for k in local.kubeconfigs : k if !fileexists(k)])
  triggers = {
    always = timestamp()
  }

  # stage kubeconfig
  provisioner "local-exec" {
    command     = <<-EOT
                  mkdir -p ~/.kube
                  touch ${each.key}
                  EOT
    interpreter = ["bash", "-c"]
  }
}

##################################################
# DEPLOYMENT
##################################################

# deploy infrastructure
module "gcp-deployment" {
  source = "../modules/deployment/gcp"
  
  # dynu api key
  dynu_api_key                         = var.dynu_api_key

  # attacker
  attacker_infrastructure_config       = module.attacker-infrastructure-context.config
  attacker_attacksurface_config        = module.attacker-attacksurface-context.config
  attacker_attacksimulate_config       = module.attacker-attacksimulation-context.config
  attacker_gcp_project                 = var.attacker_gcp_project
  attacker_gcp_region                  = var.attacker_gcp_region
  attacker_kubeconfig                  = local.attacker_kubeconfig_path
  attacker_lacework_profile            = var.attacker_lacework_profile
  attacker_lacework_account_name       = var.attacker_lacework_account_name
  attacker_lacework_server_url         = var.attacker_lacework_server_url
  attacker_lacework_agent_access_token = var.attacker_lacework_agent_access_token
  attacker_lacework_proxy_token        = var.attacker_lacework_agent_access_token
  attacker_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/attacker/resources/syscall_config.yaml")
  attacker_protonvpn_user              = var.attacker_context_config_protonvpn_user
  attacker_protonvpn_password          = var.attacker_context_config_protonvpn_password
  attacker_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
  attacker_protonvpn_server            = var.attacker_context_config_protonvpn_server
  attacker_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol
  attacker_dynu_dns_domain             = var.attacker_dynu_dns_domain

  # target
  target_infrastructure_config        = module.target-infrastructure-context.config
  target_attacksurface_config         = module.target-attacksurface-context.config
  target_attacksimulate_config        = module.target-attacksimulation-context.config
  target_gcp_project                  = var.target_gcp_project
  target_gcp_region                   = var.target_gcp_region
  target_kubeconfig                   = local.target_kubeconfig_path
  target_lacework_profile             = var.target_lacework_profile
  target_lacework_account_name        = var.target_lacework_account_name
  target_lacework_server_url          = var.target_lacework_server_url
  target_lacework_agent_access_token  = var.target_lacework_agent_access_token
  target_lacework_proxy_token         = var.target_lacework_agent_access_token
  target_lacework_sysconfig_path      = abspath("${var.scenarios_path}/${var.scenario}/target/resources/syscall_config.yaml")
  target_protonvpn_user               = var.attacker_context_config_protonvpn_user # currently only attacker has proton vpn config defined - ideally we deprecate this
  target_protonvpn_password           = var.attacker_context_config_protonvpn_password # currently only attacker has proton vpn config defined - ideally we deprecate this
  target_protonvpn_tier               = var.attacker_context_config_protonvpn_tier # currently only attacker has proton vpn config defined - ideally we deprecate this
  target_protonvpn_server             = var.attacker_context_config_protonvpn_server # currently only attacker has proton vpn config defined - ideally we deprecate this
  target_protonvpn_protocol           = var.attacker_context_config_protonvpn_protocol # currently only attacker has proton vpn config defined - ideally we deprecate this
  target_dynu_dns_domain              = var.target_dynu_dns_domain
}