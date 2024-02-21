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
module "attacker-aws-deployment" {
  source = "../modules/deployment/aws"
  
  infrastructure_config = module.attacker-infrastructure-context.config
  surface_config = module.attacker-surface-context.config
  simulate_config = module.attacker-simulate-context.config

  default_aws_profile                 = var.attacker_aws_profile
  default_aws_region                  = var.attacker_aws_region
  attacker_aws_profile                = var.attacker_aws_profile
  attacker_aws_region                 = var.attacker_aws_region
  target_aws_profile                  = var.target_aws_profile
  target_aws_region                   = var.target_aws_region
  default_kubeconfig                  = local.attacker_kubeconfig_path
  attacker_kubeconfig                 = local.attacker_kubeconfig_path
  target_kubeconfig                   = local.target_kubeconfig_path
  default_lacework_profile            = can(length(var.attacker_lacework_profile)) ? var.attacker_lacework_profile : var.lacework_profile
  default_lacework_account_name       = can(length(var.attacker_lacework_account_name)) ? var.attacker_lacework_account_name : var.lacework_account_name
  default_lacework_server_url         = can(length(var.attacker_lacework_server_url)) ? var.attacker_lacework_server_url : var.lacework_server_url
  default_lacework_agent_access_token = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_agent_access_token : var.lacework_agent_access_token
  default_lacework_proxy_token        = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_proxy_token : var.lacework_proxy_token
  default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/attacker/resources/syscall_config.yaml")
  default_protonvpn_user              = var.attacker_context_config_protonvpn_user
  default_protonvpn_password          = var.attacker_context_config_protonvpn_password
  default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
  default_protonvpn_server            = var.attacker_context_config_protonvpn_server
  default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol
}

module "target-aws-deployment" {
  source = "../modules/deployment/aws"
  
  infrastructure_config = module.attacker-infrastructure-context.config
  surface_config = module.attacker-surface-context.config
  simulate_config = module.attacker-simulate-context.config

  default_aws_profile                 = var.target_aws_profile
  default_aws_region                  = var.target_aws_region
  attacker_aws_profile                = var.attacker_aws_profile
  attacker_aws_region                 = var.attacker_aws_region
  target_aws_profile                  = var.target_aws_profile
  target_aws_region                   = var.target_aws_region
  default_kubeconfig                  = local.target_kubeconfig_path
  attacker_kubeconfig                 = local.attacker_kubeconfig_path
  target_kubeconfig                   = local.target_kubeconfig_path
  default_lacework_profile            = can(length(var.target_lacework_profile)) ? var.target_lacework_profile : var.lacework_profile
  default_lacework_account_name       = can(length(var.target_lacework_account_name)) ? var.target_lacework_account_name : var.lacework_account_name
  default_lacework_server_url         = can(length(var.target_lacework_server_url)) ? var.target_lacework_server_url : var.lacework_server_url
  default_lacework_agent_access_token = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_agent_access_token : var.lacework_agent_access_token
  default_lacework_proxy_token        = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_proxy_token : var.lacework_proxy_token
  default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/target/resources/syscall_config.yaml")
  default_protonvpn_user              = var.attacker_context_config_protonvpn_user
  default_protonvpn_password          = var.attacker_context_config_protonvpn_password
  default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
  default_protonvpn_server            = var.attacker_context_config_protonvpn_server
  default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol
}

# ##################################################
# # INFRASTRUCTURE DEPLOYMENT
# ##################################################

# # deploy infrastructure
# module "attacker-aws-infrastructure" {
#   source = "../modules/infrastructure/aws"
#   config = module.attacker-infrastructure-context.config

#   default_aws_profile                 = var.attacker_aws_profile
#   default_aws_region                  = var.attacker_aws_region
#   attacker_aws_profile                = var.attacker_aws_profile
#   attacker_aws_region                 = var.attacker_aws_region
#   target_aws_profile                  = var.target_aws_profile
#   target_aws_region                   = var.target_aws_region
#   default_kubeconfig                  = local.attacker_kubeconfig_path
#   attacker_kubeconfig                 = local.attacker_kubeconfig_path
#   target_kubeconfig                   = local.target_kubeconfig_path
#   default_lacework_profile            = can(length(var.attacker_lacework_profile)) ? var.attacker_lacework_profile : var.lacework_profile
#   default_lacework_account_name       = can(length(var.attacker_lacework_account_name)) ? var.attacker_lacework_account_name : var.lacework_account_name
#   default_lacework_server_url         = can(length(var.attacker_lacework_server_url)) ? var.attacker_lacework_server_url : var.lacework_server_url
#   default_lacework_agent_access_token = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_agent_access_token : var.lacework_agent_access_token
#   default_lacework_proxy_token        = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_proxy_token : var.lacework_proxy_token
#   default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/attacker/resources/syscall_config.yaml")
#   default_protonvpn_user              = var.attacker_context_config_protonvpn_user
#   default_protonvpn_password          = var.attacker_context_config_protonvpn_password
#   default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
#   default_protonvpn_server            = var.attacker_context_config_protonvpn_server
#   default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol

#   parent = [
#     # infrastructure context
#     module.attacker-infrastructure-context.id,
#     module.target-infrastructure-context.id,

#     # config destory delay
#     # time_sleep.wait_120_seconds.id
#   ]
# }

# module "target-aws-infrastructure" {
#   source = "../modules/infrastructure/aws"
#   config = module.target-infrastructure-context.config

#   default_aws_profile                 = var.target_aws_profile
#   default_aws_region                  = var.target_aws_region
#   attacker_aws_profile                = var.attacker_aws_profile
#   attacker_aws_region                 = var.attacker_aws_region
#   target_aws_profile                  = var.target_aws_profile
#   target_aws_region                   = var.target_aws_region
#   default_kubeconfig                  = local.target_kubeconfig_path
#   attacker_kubeconfig                 = local.attacker_kubeconfig_path
#   target_kubeconfig                   = local.target_kubeconfig_path
#   default_lacework_profile            = can(length(var.target_lacework_profile)) ? var.target_lacework_profile : var.lacework_profile
#   default_lacework_account_name       = can(length(var.target_lacework_account_name)) ? var.target_lacework_account_name : var.lacework_account_name
#   default_lacework_server_url         = can(length(var.target_lacework_server_url)) ? var.target_lacework_server_url : var.lacework_server_url
#   default_lacework_agent_access_token = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_agent_access_token : var.lacework_agent_access_token
#   default_lacework_proxy_token        = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_proxy_token : var.lacework_proxy_token
#   default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/target/resources/syscall_config.yaml")
#   default_protonvpn_user              = var.attacker_context_config_protonvpn_user
#   default_protonvpn_password          = var.attacker_context_config_protonvpn_password
#   default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
#   default_protonvpn_server            = var.attacker_context_config_protonvpn_server
#   default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol

#   parent = [
#     # infrastructure context
#     module.attacker-infrastructure-context.id,
#     module.target-infrastructure-context.id,

#     # config destory delay
#     # time_sleep.wait_120_seconds.id
#   ]
# }

# ##################################################
# # INFRASTRUCTURE LACEWORK PLATFORM
# ##################################################

# module "attacker-lacework-platform-infrastructure" {
#   source = "../modules/infrastructure/lacework/platform"
#   config = module.attacker-infrastructure-context.config

#   # infrasturcture config and deployed state
#   infrastructure = {

#     # initial configuration reference
#     config = {
#       attacker = module.attacker-infrastructure-context.config
#       target   = module.target-infrastructure-context.config
#     }

#     # deployed state configuration reference
#     deployed_state = {
#       target   = try(module.target-aws-infrastructure.config, {})
#       attacker = try(module.attacker-aws-infrastructure.config, {})
#     }
#   }

#   default_lacework_profile            = can(length(var.attacker_lacework_profile)) ? var.attacker_lacework_profile : var.lacework_profile
#   default_lacework_account_name       = can(length(var.attacker_lacework_account_name)) ? var.attacker_lacework_account_name : var.lacework_account_name
#   default_lacework_server_url         = can(length(var.attacker_lacework_server_url)) ? var.attacker_lacework_server_url : var.lacework_server_url
#   default_lacework_agent_access_token = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_agent_access_token : var.lacework_agent_access_token
#   default_lacework_proxy_token        = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_proxy_token : var.lacework_proxy_token
#   default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/attacker/resources/syscall_config.yaml")
#   default_protonvpn_user              = var.attacker_context_config_protonvpn_user
#   default_protonvpn_password          = var.attacker_context_config_protonvpn_password
#   default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
#   default_protonvpn_server            = var.attacker_context_config_protonvpn_server
#   default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol

#   parent = [
#     # infrastructure context
#     module.attacker-infrastructure-context.id,
#     module.target-infrastructure-context.id,

#     # infrastructure
#     module.attacker-aws-infrastructure.id,
#     module.target-aws-infrastructure.id,

#     # config destory delay
#     # time_sleep.wait_120_seconds.id
#   ]
# }
# module "target-lacework-platform-infrastructure" {
#   source = "../modules/infrastructure/lacework/platform"
#   config = module.target-infrastructure-context.config

#   # infrasturcture config and deployed state
#   infrastructure = {

#     # initial configuration reference
#     config = {
#       attacker = module.attacker-infrastructure-context.config
#       target   = module.target-infrastructure-context.config
#     }

#     # deployed state configuration reference
#     deployed_state = {
#       target   = try(module.target-aws-infrastructure.config, {})
#       attacker = try(module.attacker-aws-infrastructure.config, {})
#     }
#   }

#   default_lacework_profile            = can(length(var.target_lacework_profile)) ? var.target_lacework_profile : var.lacework_profile
#   default_lacework_account_name       = can(length(var.target_lacework_account_name)) ? var.target_lacework_account_name : var.lacework_account_name
#   default_lacework_server_url         = can(length(var.target_lacework_server_url)) ? var.target_lacework_server_url : var.lacework_server_url
#   default_lacework_agent_access_token = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_agent_access_token : var.lacework_agent_access_token
#   default_lacework_proxy_token        = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_proxy_token : var.lacework_proxy_token
#   default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/target/resources/syscall_config.yaml")
#   default_protonvpn_user              = var.attacker_context_config_protonvpn_user
#   default_protonvpn_password          = var.attacker_context_config_protonvpn_password
#   default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
#   default_protonvpn_server            = var.attacker_context_config_protonvpn_server
#   default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol

#   parent = [
#     # infrastructure context
#     module.attacker-infrastructure-context.id,
#     module.target-infrastructure-context.id,

#     # infrastructure
#     module.attacker-aws-infrastructure.id,
#     module.target-aws-infrastructure.id,

#     # config destory delay
#     # time_sleep.wait_120_seconds.id
#   ]
# }

# ##################################################
# # ATTACK SURFACE DEPLOYMENT
# ##################################################

# # deploy attacksurface
# module "attacker-aws-attacksurface" {
#   source = "../modules/attack/surface/aws"
#   # attack surface config
#   config = module.attacker-attacksurface-context.config

#   # infrasturcture config and deployed state
#   infrastructure = {

#     # initial configuration reference
#     config = {
#       attacker = module.attacker-infrastructure-context.config
#       target   = module.target-infrastructure-context.config
#     }

#     # deployed state configuration reference
#     deployed_state = {
#       target   = try(module.target-aws-infrastructure.config, {})
#       attacker = try(module.attacker-aws-infrastructure.config, {})
#     }
#   }

#   eks_enabled             = module.attacker-infrastructure-context.config.context.aws.eks.enabled 
#   cluster_name            = try(module.attacker-aws-infrastructure.config.context.aws.eks[0].cluster_name, null)
#   compromised_credentials = try(module.target-aws-attacksurface.compromised_credentials, "")


#   default_aws_profile                 = var.attacker_aws_profile
#   default_aws_region                  = var.attacker_aws_region
#   attacker_aws_profile                = var.attacker_aws_profile
#   attacker_aws_region                 = var.attacker_aws_region
#   target_aws_profile                  = var.target_aws_profile
#   target_aws_region                   = var.target_aws_region
#   default_kubeconfig                  = local.infrastructure_attacker_kubeconfig_path
#   attacker_kubeconfig                 = local.infrastructure_attacker_kubeconfig_path
#   target_kubeconfig                   = local.infrastructure_target_kubeconfig_path
#   default_lacework_profile            = can(length(var.attacker_lacework_profile)) ? var.attacker_lacework_profile : var.lacework_profile
#   default_lacework_account_name       = can(length(var.attacker_lacework_account_name)) ? var.attacker_lacework_account_name : var.lacework_account_name
#   default_lacework_server_url         = can(length(var.attacker_lacework_server_url)) ? var.attacker_lacework_server_url : var.lacework_server_url
#   default_lacework_agent_access_token = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_agent_access_token : var.lacework_agent_access_token
#   default_lacework_proxy_token        = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_proxy_token : var.lacework_proxy_token
#   default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/attacker/resources/syscall_config.yaml")
#   default_protonvpn_user              = var.attacker_context_config_protonvpn_user
#   default_protonvpn_password          = var.attacker_context_config_protonvpn_password
#   default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
#   default_protonvpn_server            = var.attacker_context_config_protonvpn_server
#   default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol

#   parent = [
#     # infrastructure context
#     module.attacker-infrastructure-context.id,
#     module.target-infrastructure-context.id,

#     # infrastructure
#     module.attacker-aws-infrastructure.id,
#     module.target-aws-infrastructure.id,

#     # surface context
#     module.attacker-attacksurface-context.id,
#     module.target-attacksurface-context.id,

#     # config destory delay
#     # time_sleep.wait_120_seconds.id,

#     # eks kubeconfig
#     # try(module.attacker-aws-eks-kubeconfig[0].id, null)
#   ]
# }

# module "target-aws-attacksurface" {
#   source = "../modules/attack/surface/aws"

#   # initial configuration reference
#   config = module.target-attacksurface-context.config

#   # infrasturcture config and deployed state
#   infrastructure = {
#     # initial configuration reference
#     config = {
#       attacker = module.attacker-infrastructure-context.config
#       target   = module.target-infrastructure-context.config
#     }
#     # deployed state configuration reference
#     deployed_state = {
#       target   = try(module.target-aws-infrastructure.config, {})
#       attacker = try(module.attacker-aws-infrastructure.config, {})
#     }
#   }

#   default_aws_profile                 = var.target_aws_profile
#   default_aws_region                  = var.target_aws_region
#   attacker_aws_profile                = var.attacker_aws_profile
#   attacker_aws_region                 = var.attacker_aws_region
#   target_aws_profile                  = var.target_aws_profile
#   target_aws_region                   = var.target_aws_region
#   default_kubeconfig                  = local.infrastructure_target_kubeconfig_path
#   attacker_kubeconfig                 = local.infrastructure_attacker_kubeconfig_path
#   target_kubeconfig                   = local.infrastructure_target_kubeconfig_path
#   default_lacework_profile            = can(length(var.target_lacework_profile)) ? var.target_lacework_profile : var.lacework_profile
#   default_lacework_account_name       = can(length(var.target_lacework_account_name)) ? var.target_lacework_account_name : var.lacework_account_name
#   default_lacework_server_url         = can(length(var.target_lacework_server_url)) ? var.target_lacework_server_url : var.lacework_server_url
#   default_lacework_agent_access_token = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_agent_access_token : var.lacework_agent_access_token
#   default_lacework_proxy_token        = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_proxy_token : var.lacework_proxy_token
#   default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/target/resources/syscall_config.yaml")
#   default_protonvpn_user              = var.attacker_context_config_protonvpn_user
#   default_protonvpn_password          = var.attacker_context_config_protonvpn_password
#   default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
#   default_protonvpn_server            = var.attacker_context_config_protonvpn_server
#   default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol

#   compromised_credentials = try(module.target-aws-attacksurface.compromised_credentials, "")
#   eks_enabled             = module.attacker-infrastructure-context.config.context.aws.eks.enabled 
#   cluster_name            = try(module.target-aws-infrastructure.config.context.aws.eks[0].cluster_name, null)

#   parent = [
#     # infrastructure context
#     module.attacker-infrastructure-context.id,
#     module.target-infrastructure-context.id,

#     # infrastructure
#     module.attacker-aws-infrastructure.id,
#     module.target-aws-infrastructure.id,

#     # surface context
#     module.attacker-attacksurface-context.id,
#     module.target-attacksurface-context.id,

#     # config destory delay
#     # time_sleep.wait_120_seconds.id,

#     # eks kubeconfig
#     # try(module.target-aws-eks-kubeconfig[0].id, null)
#   ]
# }

##################################################
# ATTACKSIMULATION DEPLOYMENT
##################################################

# deploy target attacksimulation
module "attacker-aws-attacksimulation" {
  source = "../modules/attack/simulate/aws"
  # attack surface config
  config = module.attacker-attacksimulation-context.config

  # infrasturcture config and deployed state
  infrastructure = {
    # initial configuration reference
    config = {
      attacker = module.attacker-infrastructure-context.config
      target   = module.target-infrastructure-context.config
    }
    # deployed state configuration reference
    deployed_state = {
      target   = try(module.target-aws-infrastructure.config, {})
      attacker = try(module.attacker-aws-infrastructure.config, {})
    }
  }

  # compromised credentials (excluded from config to avoid dynamic dependancy...)
  compromised_credentials = try(module.target-aws-attacksurface.compromised_credentials, "")
  cluster_name            = try(module.attacker-aws-infrastructure.config.context.aws.eks[0].cluster_name, null)
  ssh_user                = try(module.target-aws-attacksurface.ssh_user, null)

  default_aws_profile                 = var.attacker_aws_profile
  default_aws_region                  = var.attacker_aws_region
  attacker_aws_profile                = var.attacker_aws_profile
  attacker_aws_region                 = var.attacker_aws_region
  target_aws_profile                  = var.target_aws_profile
  target_aws_region                   = var.target_aws_region
  default_kubeconfig                  = local.infrastructure_attacker_kubeconfig_path
  attacker_kubeconfig                 = local.infrastructure_attacker_kubeconfig_path
  target_kubeconfig                   = local.infrastructure_target_kubeconfig_path
  default_lacework_profile            = can(length(var.attacker_lacework_profile)) ? var.attacker_lacework_profile : var.lacework_profile
  default_lacework_account_name       = can(length(var.attacker_lacework_account_name)) ? var.attacker_lacework_account_name : var.lacework_account_name
  default_lacework_server_url         = can(length(var.attacker_lacework_server_url)) ? var.attacker_lacework_server_url : var.lacework_server_url
  default_lacework_agent_access_token = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_agent_access_token : var.lacework_agent_access_token
  default_lacework_proxy_token        = can(length(var.attacker_lacework_agent_access_token)) ? var.attacker_lacework_proxy_token : var.lacework_proxy_token
  default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/attacker/resources/syscall_config.yaml")
  default_protonvpn_user              = var.attacker_context_config_protonvpn_user
  default_protonvpn_password          = var.attacker_context_config_protonvpn_password
  default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
  default_protonvpn_server            = var.attacker_context_config_protonvpn_server
  default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-aws-infrastructure.id,
    module.target-aws-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # surface
    module.attacker-aws-attacksurface.id,
    module.target-aws-attacksurface.id,

    # simulation context
    module.attacker-attacksimulation-context.id,
    module.target-attacksimulation-context.id,

    # config destory delay
    # time_sleep.wait_120_seconds.id,

    # eks kubeconfig
    # try(module.attacker-aws-eks-kubeconfig[0].id, null)
  ]
}


# deploy target attacksimulation
module "target-aws-attacksimulation" {
  source = "../modules/attack/simulate/aws"
  # attack surface config
  config = module.target-attacksimulation-context.config

  # infrasturcture config and deployed state
  infrastructure = {
    # initial configuration reference
    config = {
      attacker = module.attacker-infrastructure-context.config
      target   = module.target-infrastructure-context.config
    }
    # deployed state configuration reference
    deployed_state = {
      target   = try(module.target-aws-infrastructure.config, {})
      attacker = try(module.attacker-aws-infrastructure.config, {})
    }
  }

  # compromised credentials (excluded from config to avoid dynamic dependancy...)
  compromised_credentials = try(module.target-aws-attacksurface.compromised_credentials, "")
  cluster_name            = try(module.target-aws-infrastructure.config.context.aws.eks[0].cluster_name, null)
  ssh_user                = try(module.target-aws-attacksurface.ssh_user, null)

  default_aws_profile                 = var.target_aws_profile
  default_aws_region                  = var.target_aws_region
  attacker_aws_profile                = var.attacker_aws_profile
  attacker_aws_region                 = var.attacker_aws_region
  target_aws_profile                  = var.target_aws_profile
  target_aws_region                   = var.target_aws_region
  default_kubeconfig                  = local.infrastructure_target_kubeconfig_path
  attacker_kubeconfig                 = local.infrastructure_attacker_kubeconfig_path
  target_kubeconfig                   = local.infrastructure_target_kubeconfig_path
  default_lacework_profile            = can(length(var.target_lacework_profile)) ? var.target_lacework_profile : var.lacework_profile
  default_lacework_account_name       = can(length(var.target_lacework_account_name)) ? var.target_lacework_account_name : var.lacework_account_name
  default_lacework_server_url         = can(length(var.target_lacework_server_url)) ? var.target_lacework_server_url : var.lacework_server_url
  default_lacework_agent_access_token = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_agent_access_token : var.lacework_agent_access_token
  default_lacework_proxy_token        = can(length(var.target_lacework_agent_access_token)) ? var.target_lacework_proxy_token : var.lacework_proxy_token
  default_lacework_sysconfig_path     = abspath("${var.scenarios_path}/${var.scenario}/target/resources/syscall_config.yaml")
  default_protonvpn_user              = var.attacker_context_config_protonvpn_user
  default_protonvpn_password          = var.attacker_context_config_protonvpn_password
  default_protonvpn_tier              = var.attacker_context_config_protonvpn_tier
  default_protonvpn_server            = var.attacker_context_config_protonvpn_server
  default_protonvpn_protocol          = var.attacker_context_config_protonvpn_protocol

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-aws-infrastructure.id,
    module.target-aws-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # surface
    module.attacker-aws-attacksurface.id,
    module.target-aws-attacksurface.id,

    # simulation context
    module.attacker-attacksimulation-context.id,
    module.target-attacksimulation-context.id,

    # config destory delay
    # time_sleep.wait_120_seconds.id,

    # eks kubeconfig
    # try(module.attacker-aws-eks-kubeconfig[0].id, null)
  ]
}