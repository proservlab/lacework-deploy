##################################################
# KUBECONFIG STAGING
##################################################

locals {
  default_kubeconfig_path  = pathexpand("~/.kube/config")
  attacker_kubeconfig_path = pathexpand("~/.kube/aws-attacker-${var.deployment}-kubeconfig")
  target_kubeconfig_path   = pathexpand("~/.kube/aws-target-${var.deployment}-kubeconfig")

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

module "aws-deployment" {
  source = "../modules/deployment/aws"
  
  # attacker
  attacker_infrastructure_config = module.attacker-infrastructure-context.config
  attacker_surface_config = module.attacker-surface-context.config
  attacker_simulate_config = module.attacker-simulate-context.config
  attacker_aws_profile                 = var.target_aws_profile
  attacker_aws_region                  = var.target_aws_region
  attacker_kubeconfig                  = local.target_kubeconfig_path
  attacker_lacework_profile            = can(length(var.target_lacework_profile)) ? var.target_lacework_profile : var.lacework_profile
  attacker_lacework_account_name       = can(length(var.target_lacework_account_name)) ? var.target_lacework_account_name : var.lacework_account_name
  attacker_lacework_server_url         = can(length(var.target_lacework_server_url)) ? var.target_lacework_server_url : var.lacework_server_url
  attacker_lacework_agent_access_token = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_agent_access_token : var.lacework_agent_access_token
  attacker_lacework_proxy_token        = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_proxy_token : var.lacework_proxy_token
  attacker_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/target/resources/syscall_config.yaml")
  attacker_protonvpn_user              = var.attacker_context_config_protonvpn_user
  attacker_protonvpn_password          = var.attacker_context_config_protonvpn_password
  attacker_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
  attacker_protonvpn_server            = var.attacker_context_config_protonvpn_server
  attacker_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol

  # target
  target_infrastructure_config = module.attacker-infrastructure-context.config
  target_surface_config = module.attacker-surface-context.config
  target_simulate_config = module.attacker-simulate-context.config
  target_aws_profile                  = var.target_aws_profile
  target_aws_region                   = var.target_aws_region
  target_kubeconfig                   = local.target_kubeconfig_path
  target_lacework_profile             = can(length(var.target_lacework_profile)) ? var.target_lacework_profile : var.lacework_profile
  target_lacework_account_name        = can(length(var.target_lacework_account_name)) ? var.target_lacework_account_name : var.lacework_account_name
  target_lacework_server_url          = can(length(var.target_lacework_server_url)) ? var.target_lacework_server_url : var.lacework_server_url
  target_lacework_agent_access_token  = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_agent_access_token : var.lacework_agent_access_token
  target_lacework_proxy_token         = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_proxy_token : var.lacework_proxy_token
  target_lacework_sysconfig_path      = abspath("${var.scenarios_path}/${var.scenario}/target/resources/syscall_config.yaml")
  target_protonvpn_user               = var.attacker_context_config_protonvpn_user
  target_protonvpn_password           = var.attacker_context_config_protonvpn_password
  target_protonvpn_tier               = var.attacker_context_config_protonvpn_tier
  target_protonvpn_server             = var.attacker_context_config_protonvpn_server
  target_protonvpn_protocol           = var.attacker_context_config_protonvpn_protocol
}