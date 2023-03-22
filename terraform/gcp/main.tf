##################################################
# DEFAULT
##################################################

# unique id used for deployment
module "deployment" {
  source = "../modules/context/deployment"
}

# defaults
module "default-infrastructure-context" {
  source = "../modules/context/infrastructure"

  parent = [
    module.deployment.id
  ]
}

module "default-attacksurface-context" {
  source = "../modules/context/attack/surface"

  parent = [
    module.deployment.id
  ]
}

module "default-attacksimulation-context" {
  source = "../modules/context/attack/simulate"

  parent = [
    module.deployment.id
  ]
}

##################################################
# KUBECONFIG STAGING
##################################################

locals {
  kubeconfigs = [
    pathexpand("~/.kube/gcp-attacker-${var.deployment}-kubeconfig"),
    pathexpand("~/.kube/gcp-target-${var.deployment}-kubeconfig"),
    pathexpand("~/.kube/gcp-target-default-kubeconfig")
  ]
}
# stage the kubeconfig files to avoid errors
resource "null_resource" "kubeconfig" {
  triggers = {
    always = timestamp()
  }
  count = length(local.kubeconfigs)

  # stage kubeconfig
  provisioner "local-exec" {
    command     = <<-EOT
                  mkdir -p ~/.kube
                  touch ${local.kubeconfigs[count.index]}
                  EOT
    interpreter = ["bash", "-c"]
  }
}

##################################################
# INFRASTRUCTURE CONFIG
##################################################

locals {
  attacker-infrastructure-config-file = templatefile(
    "${path.module}/scenarios/${var.scenario}/attacker/infrastructure.json",
    {
      # deployment id
      deployment = var.deployment

      # gcp
      gcp_project = can(length(var.attacker_gcp_project)) ? var.attacker_gcp_project : ""
      gcp_region  = var.attacker_gcp_region

      # dynu config
      dynu_api_token  = var.dynu_api_token
      dynu_dns_domain = var.dynu_dns_domain

      # lacework
      lacework_profile = var.lacework_profile
    }
  )
  target-infrastructure-config-file = templatefile(
    "${path.module}/scenarios/${var.scenario}/target/infrastructure.json",
    {
      # deployment id
      deployment = var.deployment

      # gcp
      gcp_project          = can(length(var.target_gcp_project)) ? var.target_gcp_project : ""
      gcp_region           = var.target_gcp_region
      gcp_lacework_project = can(length(var.target_gcp_lacework_project)) ? var.target_gcp_lacework_project : ""

      # dynu config
      dynu_api_token  = var.dynu_api_token
      dynu_dns_domain = var.dynu_dns_domain

      # lacework
      lacework_server_url   = var.lacework_server_url
      lacework_account_name = var.lacework_account_name
      lacework_profile      = var.lacework_profile
      syscall_config_path   = abspath("${path.module}/scenarios/${var.scenario}/target/resources/syscall_config.yaml")

      # slack
      slack_token = var.slack_token

      # jira config
      jira_cloud_url         = var.jira_cloud_url
      jira_cloud_username    = var.jira_cloud_username
      jira_cloud_api_token   = var.jira_cloud_api_token
      jira_cloud_project_key = var.jira_cloud_project_key
      jira_cloud_issue_type  = var.jira_cloud_issue_type
    }
  )
}

data "utils_deep_merge_json" "attacker-infrastructure-config" {
  input = [
    jsonencode(module.default-infrastructure-context.config),
    local.attacker-infrastructure-config-file
  ]
}

data "utils_deep_merge_json" "target-infrastructure-config" {
  input = [
    jsonencode(module.default-infrastructure-context.config),
    local.target-infrastructure-config-file
  ]
}


##################################################
# INFRASTRUCTURE CONTEXT
##################################################

# set infrasturcture context and validate the schema
module "attacker-infrastructure-context" {
  source = "../modules/context/infrastructure"
  config = jsondecode(data.utils_deep_merge_json.attacker-infrastructure-config.output)

  parent = [
    module.deployment.id
  ]
}

module "target-infrastructure-context" {
  source = "../modules/context/infrastructure"
  config = jsondecode(data.utils_deep_merge_json.target-infrastructure-config.output)

  parent = [
    module.deployment.id
  ]
}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [
    module.attacker-infrastructure-context,
    module.target-infrastructure-context
  ]

  destroy_duration = "120s"
}

##################################################
# INFRASTRUCTURE DEPLOYMENT
##################################################

module "attacker-gcp-infrastructure" {
  source = "../modules/infrastructure/gcp"
  config = module.attacker-infrastructure-context.config

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

module "target-gcp-infrastructure" {
  source = "../modules/infrastructure/gcp"
  config = module.target-infrastructure-context.config

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

##################################################
# INFRASTRUCTURE LACEWORK DEPLOYMENT
#
# Note: Lacework Kubernetes Modules Require EKS/GKE
##################################################

module "attacker-lacework-platform-infrastructure" {
  source = "../modules/infrastructure/lacework/platform"
  config = module.attacker-infrastructure-context.config

  # infrasturcture config and deployed state
  infrastructure = {

    # initial configuration reference
    config = {
      attacker = module.attacker-infrastructure-context.config
      target   = module.target-infrastructure-context.config
    }

    # deployed state configuration reference
    deployed_state = {
      target   = try(module.target-gcp-infrastructure.config, {})
      attacker = try(module.attacker-gcp-infrastructure.config, {})
    }
  }

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

module "attacker-lacework-gcp-infrastructure" {
  source = "../modules/infrastructure/lacework/gcp"
  config = module.attacker-infrastructure-context.config

  # infrasturcture config and deployed state
  infrastructure = {

    # initial configuration reference
    config = {
      attacker = module.attacker-infrastructure-context.config
      target   = module.target-infrastructure-context.config
    }

    # deployed state configuration reference
    deployed_state = {
      target   = try(module.target-gcp-infrastructure.config, {})
      attacker = try(module.attacker-gcp-infrastructure.config, {})
    }
  }

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

module "target-lacework-platform-infrastructure" {
  source = "../modules/infrastructure/lacework/platform"
  config = module.target-infrastructure-context.config

  # infrasturcture config and deployed state
  infrastructure = {

    # initial configuration reference
    config = {
      attacker = module.attacker-infrastructure-context.config
      target   = module.target-infrastructure-context.config
    }

    # deployed state configuration reference
    deployed_state = {
      target   = try(module.target-gcp-infrastructure.config, {})
      attacker = try(module.attacker-gcp-infrastructure.config, {})
    }
  }

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

module "target-lacework-gcp-infrastructure" {
  source = "../modules/infrastructure/lacework/gcp"
  config = module.target-infrastructure-context.config

  # infrasturcture config and deployed state
  infrastructure = {

    # initial configuration reference
    config = {
      attacker = module.attacker-infrastructure-context.config
      target   = module.target-infrastructure-context.config
    }

    # deployed state configuration reference
    deployed_state = {
      target   = try(module.target-gcp-infrastructure.config, {})
      attacker = try(module.attacker-gcp-infrastructure.config, {})
    }
  }

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

##################################################
# ATTACK SURFACE CONFIG
##################################################

locals {
  attacker-attacksurface-config-file = templatefile(
    "${path.module}/scenarios/${var.scenario}/attacker/surface.json",
    {
      # deployment id
      deployment = var.deployment
    }
  )
  target-attacksurface-config-file = templatefile(
    "${path.module}/scenarios/${var.scenario}/target/surface.json",
    {
      # deployment id
      deployment = var.deployment

      # iam
      iam_power_user_policy_path = abspath("${path.module}/scenarios/${var.scenario}/target/resources/iam_power_user_policy.json")
      iam_users_path             = abspath("${path.module}/scenarios/${var.scenario}/target/resources/iam_users.json")
    }
  )
}

data "utils_deep_merge_json" "attacker-attacksurface-config" {
  input = [
    jsonencode(module.default-attacksurface-context.config),
    local.attacker-attacksurface-config-file
  ]
}

data "utils_deep_merge_json" "target-attacksurface-config" {
  input = [
    jsonencode(module.default-attacksurface-context.config),
    local.target-attacksurface-config-file
  ]
}

##################################################
# ATTACK SURFACE CONTEXT
##################################################

# set attack the context
module "attacker-attacksurface-context" {
  source = "../modules/context/attack/surface"
  config = jsondecode(data.utils_deep_merge_json.attacker-attacksurface-config.output)

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

module "target-attacksurface-context" {
  source = "../modules/context/attack/surface"
  config = jsondecode(data.utils_deep_merge_json.target-attacksurface-config.output)

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

##################################################
# ATTACK SURFACE DEPLOYMENT
##################################################

module "attacker-gcp-attacksurface" {
  source = "../modules/attack/surface/gcp"
  # attack surface config
  config = module.attacker-attacksurface-context.config

  # infrasturcture config and deployed state
  infrastructure = {

    # initial configuration reference
    config = {
      attacker = module.attacker-infrastructure-context.config
      target   = module.target-infrastructure-context.config
    }

    # deployed state configuration reference
    deployed_state = {
      target   = try(module.target-gcp-infrastructure.config, {})
      attacker = try(module.attacker-gcp-infrastructure.config, {})
    }
  }

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

module "target-gcp-attacksurface" {
  source = "../modules/attack/surface/gcp"

  # initial configuration reference
  config = module.target-attacksurface-context.config

  # infrasturcture config and deployed state
  infrastructure = {
    # initial configuration reference
    config = {
      attacker = module.attacker-infrastructure-context.config
      target   = module.target-infrastructure-context.config
    }
    # deployed state configuration reference
    deployed_state = {
      target   = try(module.target-gcp-infrastructure.config, {})
      attacker = try(module.attacker-gcp-infrastructure.config, {})
    }
  }

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

##################################################
# ATTACKSIMULATION CONFIG
##################################################

locals {

  attacker-attacksimulation-config-file = templatefile(
    "${path.module}/scenarios/${var.scenario}/shared/simulation.json",
    {
      # environment
      environment = "attacker"
      deployment  = var.deployment

      # dynu
      dynu_dns_domain = var.dynu_dns_domain

      # aws
      attacker_aws_profile = can(length(var.attacker_aws_profile)) ? var.attacker_aws_profile : ""
      attacker_aws_region  = var.attacker_aws_region
      target_aws_profile   = can(length(var.target_aws_profile)) ? var.target_aws_profile : ""
      target_aws_region    = var.target_aws_region

      # azure
      attacker_azure_subscription = can(length(var.attacker_azure_subscription)) ? var.attacker_azure_subscription : ""
      attacker_azure_tenant       = can(length(var.attacker_azure_tenant)) ? var.attacker_azure_tenant : ""
      attacker_azure_region       = var.attacker_azure_region
      target_azure_subscription   = can(length(var.target_azure_subscription)) ? var.target_azure_subscription : ""
      target_azure_tenant         = can(length(var.target_azure_tenant)) ? var.target_azure_tenant : ""
      target_azure_region         = var.target_azure_region

      # gcp
      attacker_gcp_project        = can(length(var.attacker_gcp_project)) ? var.attacker_gcp_project : ""
      attacker_gcp_region         = var.attacker_gcp_region
      target_gcp_project          = can(length(var.target_gcp_project)) ? var.target_gcp_project : ""
      target_gcp_region           = var.target_gcp_region
      target_gcp_lacework_project = can(length(var.target_gcp_lacework_project)) ? var.target_gcp_lacework_project : ""

      # azure
      attacker_azure_region = var.attacker_azure_region
      target_azure_region   = var.target_azure_region

      # variables
      compromised_credentials                              = abspath("${path.module}/scenarios/${var.scenario}/target/resources/iam_users.json")
      attacker_context_config_protonvpn_user               = var.attacker_context_config_protonvpn_user
      attacker_context_config_protonvpn_password           = var.attacker_context_config_protonvpn_password
      attacker_context_config_protonvpn_tier               = var.attacker_context_config_protonvpn_tier
      attacker_context_cloud_cryptomining_ethermine_wallet = var.attacker_context_cloud_cryptomining_ethermine_wallet
      attacker_context_host_cryptomining_minergate_user    = var.attacker_context_host_cryptomining_minergate_user
      attacker_context_host_cryptomining_nicehash_user     = var.attacker_context_host_cryptomining_nicehash_user
    }
  )
  target-attacksimulation-config-file = templatefile(
    "${path.module}/scenarios/${var.scenario}/shared/simulation.json",
    {
      # environment
      environment = "target"
      deployment  = var.deployment

      # dynu
      dynu_dns_domain = var.dynu_dns_domain

      # aws
      attacker_aws_profile = can(length(var.attacker_aws_profile)) ? var.attacker_aws_profile : ""
      attacker_aws_region  = var.attacker_aws_region
      target_aws_profile   = can(length(var.target_aws_profile)) ? var.target_aws_profile : ""
      target_aws_region    = var.target_aws_region

      # azure
      attacker_azure_subscription = can(length(var.attacker_azure_subscription)) ? var.attacker_azure_subscription : ""
      attacker_azure_tenant       = can(length(var.attacker_azure_tenant)) ? var.attacker_azure_tenant : ""
      attacker_azure_region       = var.attacker_azure_region
      target_azure_subscription   = can(length(var.target_azure_subscription)) ? var.target_azure_subscription : ""
      target_azure_tenant         = can(length(var.target_azure_tenant)) ? var.target_azure_tenant : ""
      target_azure_region         = var.target_azure_region

      # gcp
      attacker_gcp_project        = can(length(var.attacker_gcp_project)) ? var.attacker_gcp_project : ""
      attacker_gcp_region         = var.attacker_gcp_region
      target_gcp_project          = can(length(var.target_gcp_project)) ? var.target_gcp_project : ""
      target_gcp_region           = var.target_gcp_region
      target_gcp_lacework_project = can(length(var.target_gcp_lacework_project)) ? var.target_gcp_lacework_project : ""

      # azure
      attacker_azure_region = var.attacker_azure_region
      target_azure_region   = var.target_azure_region

      # variables
      attacker_context_config_protonvpn_user               = var.attacker_context_config_protonvpn_user
      attacker_context_config_protonvpn_password           = var.attacker_context_config_protonvpn_password
      attacker_context_config_protonvpn_tier               = var.attacker_context_config_protonvpn_tier
      attacker_context_cloud_cryptomining_ethermine_wallet = var.attacker_context_cloud_cryptomining_ethermine_wallet
      attacker_context_host_cryptomining_minergate_user    = var.attacker_context_host_cryptomining_minergate_user
      attacker_context_host_cryptomining_nicehash_user     = var.attacker_context_host_cryptomining_nicehash_user
    }
  )
}

data "utils_deep_merge_json" "attacker-attacksimulation-config" {
  input = [
    jsonencode(module.default-attacksimulation-context.config),
    local.attacker-attacksimulation-config-file
  ]
}

data "utils_deep_merge_json" "target-attacksimulation-config" {
  input = [
    jsonencode(module.default-attacksimulation-context.config),
    local.target-attacksimulation-config-file
  ]
}

##################################################
# ATTACKSIMULATION CONTEXT
##################################################

# set attack the context
module "attacker-attacksimulation-context" {
  source = "../modules/context/attack/simulate"
  config = jsondecode(data.utils_deep_merge_json.attacker-attacksimulation-config.output)

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # surface
    module.attacker-gcp-attacksurface.id,
    module.target-gcp-attacksurface.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

# set attack the context
module "target-attacksimulation-context" {
  source = "../modules/context/attack/simulate"
  config = jsondecode(data.utils_deep_merge_json.target-attacksimulation-config.output)

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # surface
    module.attacker-gcp-attacksurface.id,
    module.target-gcp-attacksurface.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

##################################################
# ATTACKSIMULATION DEPLOYMENT
##################################################

# deploy target attacksimulation
module "attacker-gcp-attacksimulation" {
  source = "../modules/attack/simulate/gcp"
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
      target   = try(module.target-gcp-infrastructure.config, {})
      attacker = try(module.attacker-gcp-infrastructure.config, {})
    }
  }

  # compromised credentials (excluded from config to avoid dynamic dependancy...)
  compromised_credentials = try(module.target-gcp-attacksurface.compromised_credentials, "")

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # surface
    module.attacker-gcp-attacksurface.id,
    module.target-gcp-attacksurface.id,

    # simulation context
    module.attacker-attacksimulation-context.id,
    module.target-attacksimulation-context.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}

# deploy target attacksimulation
module "target-gcp-attacksimulation" {
  source = "../modules/attack/simulate/gcp"
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
      target   = try(module.target-gcp-infrastructure.config, {})
      attacker = try(module.attacker-gcp-infrastructure.config, {})
    }
  }

  # compromised credentials (excluded from config to avoid dynamic dependancy...)
  compromised_credentials = try(module.target-gcp-attacksurface.compromised_credentials, "")

  parent = [
    # infrastructure context
    module.attacker-infrastructure-context.id,
    module.target-infrastructure-context.id,

    # infrastructure
    module.attacker-gcp-infrastructure.id,
    module.target-gcp-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # surface
    module.attacker-gcp-attacksurface.id,
    module.target-gcp-attacksurface.id,

    # simulation context
    module.attacker-attacksimulation-context.id,
    module.target-attacksimulation-context.id,

    # config destory delay
    time_sleep.wait_120_seconds.id
  ]
}