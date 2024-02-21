##################################################
# DEFAULT
##################################################

# defaults
module "default-infrastructure-context" {
  source = "../modules/context/infrastructure"
}

module "default-attacksurface-context" {
  source = "../modules/context/attack/surface"
}

module "default-attacksimulation-context" {
  source = "../modules/context/attack/simulate"
}

##################################################
# INFRASTRUCTURE CONFIG
##################################################

locals {
  attacker-infrastructure-config-file = templatefile(
    "${var.scenarios_path}/${var.scenario}/attacker/infrastructure.json",
    {
      # deployment id
      deployment = var.deployment

      # aws
      aws_profile = can(length(var.attacker_aws_profile)) ? var.attacker_aws_profile : ""
      aws_region  = var.attacker_aws_region

      # dynu config
      dynu_api_key    = var.attacker_dynu_api_key
      dynu_dns_domain = var.attacker_dynu_dns_domain

      # lacework
      lacework_profile      = can(length(var.attacker_lacework_profile)) ? var.attacker_lacework_profile : var.lacework_profile
      lacework_account_name = can(length(var.attacker_lacework_account_name)) ? var.attacker_lacework_account_name : var.lacework_account_name
      lacework_server_url   = can(length(var.attacker_lacework_server_url)) ? var.attacker_lacework_server_url : var.lacework_server_url
      syscall_config_path   = abspath("${var.scenarios_path}/${var.scenario}/attacker/resources/syscall_config.yaml")
    }
  )
  target-infrastructure-config-file = templatefile(
    "${var.scenarios_path}/${var.scenario}/target/infrastructure.json",
    {
      # deployment id
      deployment = var.deployment

      # aws
      aws_profile = can(length(var.target_aws_profile)) ? var.target_aws_profile : ""
      aws_region  = var.target_aws_region

      # dynu config
      dynu_api_key    = var.target_dynu_api_key
      dynu_dns_domain = var.target_dynu_dns_domain

      # lacework
      lacework_profile      = can(length(var.target_lacework_profile)) ? var.target_lacework_profile : var.lacework_profile
      lacework_account_name = can(length(var.target_lacework_account_name)) ? var.target_lacework_account_name : var.lacework_account_name
      lacework_server_url   = can(length(var.target_lacework_server_url)) ? var.target_lacework_server_url : var.lacework_server_url
      syscall_config_path   = abspath("${var.scenarios_path}/${var.scenario}/target/resources/syscall_config.yaml")

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
  attacker_infrastructure_temp_config = jsondecode(local.attacker-infrastructure-config-file)
  target_infrastructure_temp_config   = jsondecode(local.target-infrastructure-config-file)

  # prevent misconfiguration on agentless vpc discovery
  attacker_infrastructure_override = {
    context = {
      lacework = {
        aws_agentless = {
          use_existing_vpc = length(flatten([
            [
              for x in local.attacker_infrastructure_temp_config["context"]["aws"]["ec2"]["instances"] : x if x["public"] == true && x["role"] == "default"
            ],
            [
              for x in local.attacker_infrastructure_temp_config["context"]["aws"]["ec2"]["instances"] : x if x["public"] == true && x["role"] == "app"
            ],
            ])) > 0 ? (
            # if vpcs will be created we can accept either true or false for use_existing_vpc from config
            try(local.attacker_infrastructure_temp_config["context"]["lacework"]["aws_agentless"]["use_existing_vpc"], module.default-infrastructure-context.config["context"]["lacework"]["aws_agentless"]["use_existing_vpc"])
            ) : (
            # if no vpcs will be created we should check to see if we have been passed a vpc id and allow true or false for use_existing_vpc from config
            try(length(local.attacker_infrastructure_temp_config["context"]["lacework"]["aws_agentless"]["vpc_id"]), "false") != "false" ? (
              try(local.attacker_infrastructure_temp_config["context"]["lacework"]["aws_agentless"]["use_existing_vpc"], module.default-infrastructure-context.config["context"]["lacework"]["aws_agentless"]["use_existing_vpc"])
              ) : (
              # no vpc will be created and no vpc_id passed use_existing_vpc should be false
              false
            )
          )
        }
      }
    }
  }
  target_infrastructure_override = {
    context = {
      lacework = {
        aws_agentless = {
          use_existing_vpc = length(flatten([
            [
              for x in local.target_infrastructure_temp_config["context"]["aws"]["ec2"]["instances"] : x if x["public"] == true && x["role"] == "default"
            ],
            [
              for x in local.target_infrastructure_temp_config["context"]["aws"]["ec2"]["instances"] : x if x["public"] == true && x["role"] == "app"
            ],
            ])) > 0 ? (
            # if vpcs will be created we can accept either true or false for use_existing_vpc from config
            try(local.target_infrastructure_temp_config["context"]["lacework"]["aws_agentless"]["use_existing_vpc"], module.default-infrastructure-context.config["context"]["lacework"]["aws_agentless"]["use_existing_vpc"])
            ) : (
            # if no vpcs will be created we should check to see if we have been passed a vpc id and allow true or false for use_existing_vpc from config
            try(length(local.target_infrastructure_temp_config["context"]["lacework"]["aws_agentless"]["vpc_id"]), "false") != "false" ? (
              try(local.target_infrastructure_temp_config["context"]["lacework"]["aws_agentless"]["use_existing_vpc"], module.default-infrastructure-context.config["context"]["lacework"]["aws_agentless"]["use_existing_vpc"])
              ) : (
              # no vpc will be created and no vpc_id passed use_existing_vpc should be false
              false
            )
          )
        }
      }
    }
  }
}

##################################################
# INFRASTRUCTURE MERGE WITH OVERRIDE
##################################################

data "utils_deep_merge_json" "attacker-infrastructure-config" {
  input = [
    jsonencode(module.default-infrastructure-context.config),
    local.attacker-infrastructure-config-file,
    jsonencode(local.attacker_infrastructure_override)
  ]
}

data "utils_deep_merge_json" "target-infrastructure-config" {
  input = [
    jsonencode(module.default-infrastructure-context.config),
    local.target-infrastructure-config-file,
    jsonencode(local.target_infrastructure_override)
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

##################################################
# ATTACK SURFACE CONFIG
##################################################

locals {
  attacker-attacksurface-config-file = templatefile(
    "${var.scenarios_path}/${var.scenario}/attacker/surface.json",
    {
      # deployment id
      deployment = var.deployment

      # dynu config
      dynu_api_key    = var.attacker_dynu_api_key
      dynu_dns_domain = var.attacker_dynu_dns_domain

      # iam
      iam_power_user_policy_path = abspath("${var.scenarios_path}/${var.scenario}/target/resources/iam_user_policies.json")
      iam_users_path             = abspath("${var.scenarios_path}/${var.scenario}/target/resources/iam_users.json")
    }
  )
  target-attacksurface-config-file = templatefile(
    "${var.scenarios_path}/${var.scenario}/target/surface.json",
    {
      # deployment id
      deployment = var.deployment

      # dynu config
      dynu_api_key    = var.target_dynu_api_key
      dynu_dns_domain = var.target_dynu_dns_domain

      # iam
      iam_power_user_policy_path = abspath("${var.scenarios_path}/${var.scenario}/target/resources/iam_user_policies.json")
      iam_users_path             = abspath("${var.scenarios_path}/${var.scenario}/target/resources/iam_users.json")
    }
  )

  attacker_attacksurface_temp_config = jsondecode(local.attacker-attacksurface-config-file)
  target_attacksurface_temp_config   = jsondecode(local.target-attacksurface-config-file)
  attacker_attacksurface_override = {
    context = {
      aws = {
        ec2 = {
          add_trusted_ingress = {
            enabled = length([for x in local.attacker_infrastructure_temp_config["context"]["aws"]["ec2"]["instances"] : x if x["public"] == true && x["role"] == "default"]) > 0 ? try(local.attacker_attacksurface_temp_config["context"]["aws"]["ec2"]["add_trusted_ingress"]["enabled"], false) : false
          }
          add_app_trusted_ingress = {
            enabled = length([for x in local.attacker_infrastructure_temp_config["context"]["aws"]["ec2"]["instances"] : x if x["public"] == true && x["role"] == "app"]) > 0 ? try(local.attacker_attacksurface_temp_config["context"]["aws"]["ec2"]["add_app_trusted_ingress"]["enabled"], false) : false
          }
        }
      }
    }
  }
  target_attacksurface_override = {
    context = {
      aws = {
        ec2 = {
          add_trusted_ingress = {
            enabled = length([for x in local.target_infrastructure_temp_config["context"]["aws"]["ec2"]["instances"] : x if x["public"] == true && x["role"] == "default"]) > 0 ? try(local.target_attacksurface_temp_config["context"]["aws"]["ec2"]["add_trusted_ingress"]["enabled"], false) : false
          }
          add_app_trusted_ingress = {
            enabled = length([for x in local.target_infrastructure_temp_config["context"]["aws"]["ec2"]["instances"] : x if x["public"] == true && x["role"] == "app"]) > 0 ? try(local.target_attacksurface_temp_config["context"]["aws"]["ec2"]["add_app_trusted_ingress"]["enabled"], false) : false
          }
        }
      }
    }
  }

  infrastructure_target_kubeconfig_path = local.target_kubeconfig_path
  # infrastructure_target_kubeconfig_path   = can(fileexists(pathexpand(module.target-aws-infrastructure["config"].context.aws.eks[0].kubeconfig_path))) ? pathexpand(module.target-aws-infrastructure["config"].context.aws.eks[0].kubeconfig_path) : pathexpand("~/.kube/config")
  infrastructure_attacker_kubeconfig_path = local.attacker_kubeconfig_path
  #infrastructure_attacker_kubeconfig_path = can(fileexists(pathexpand(module.attacker-aws-infrastructure["config"].context.aws.eks[0].kubeconfig_path))) ? pathexpand(module.attacker-aws-infrastructure["config"].context.aws.eks[0].kubeconfig_path) : pathexpand("~/.kube/config")
}

data "utils_deep_merge_json" "attacker-attacksurface-config" {
  input = [
    jsonencode(module.default-attacksurface-context.config),
    local.attacker-attacksurface-config-file,
    jsonencode(local.attacker_attacksurface_override)
  ]
}

data "utils_deep_merge_json" "target-attacksurface-config" {
  input = [
    jsonencode(module.default-attacksurface-context.config),
    local.target-attacksurface-config-file,
    jsonencode(local.target_attacksurface_override)
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
    module.attacker-aws-infrastructure.id,
    module.target-aws-infrastructure.id,

    # config destory delay
    # time_sleep.wait_120_seconds.id
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
    module.attacker-aws-infrastructure.id,
    module.target-aws-infrastructure.id,

    # config destory delay
    # time_sleep.wait_120_seconds.id
  ]
}

##################################################
# ATTACKSIMULATION CONFIG
##################################################

locals {
  attacker-attacksimulation-config-file = templatefile(
    "${var.scenarios_path}/${var.scenario}/shared/simulation.json",
    {
      # environment
      environment = "attacker"
      deployment  = var.deployment

      # dynu config
      dynu_api_key    = var.attacker_dynu_api_key
      dynu_dns_domain = var.attacker_dynu_dns_domain

      # aws
      attacker_aws_profile = can(length(var.attacker_aws_profile)) ? var.attacker_aws_profile : ""
      attacker_aws_region  = var.attacker_aws_region
      target_aws_profile   = can(length(var.target_aws_profile)) ? var.target_aws_profile : ""
      target_aws_region    = var.target_aws_region

      # variables
      compromised_credentials                              = abspath("${var.scenarios_path}/${var.scenario}/target/resources/iam_users.json")
      attacker_context_config_protonvpn_user               = var.attacker_context_config_protonvpn_user
      attacker_context_config_protonvpn_password           = var.attacker_context_config_protonvpn_password
      attacker_context_config_protonvpn_tier               = var.attacker_context_config_protonvpn_tier
      attacker_context_cloud_cryptomining_ethermine_wallet = var.attacker_context_cloud_cryptomining_ethermine_wallet
      attacker_context_host_cryptomining_minergate_user    = var.attacker_context_host_cryptomining_minergate_user
      attacker_context_host_cryptomining_nicehash_user     = var.attacker_context_host_cryptomining_nicehash_user
    }
  )
  target-attacksimulation-config-file = templatefile(
    "${var.scenarios_path}/${var.scenario}/shared/simulation.json",
    {
      # environment
      environment = "target"
      deployment  = var.deployment

      # dynu config
      dynu_api_key    = var.target_dynu_api_key
      dynu_dns_domain = var.target_dynu_dns_domain

      # aws
      attacker_aws_profile = can(length(var.attacker_aws_profile)) ? var.attacker_aws_profile : ""
      attacker_aws_region  = var.attacker_aws_region
      target_aws_profile   = can(length(var.target_aws_profile)) ? var.target_aws_profile : ""
      target_aws_region    = var.target_aws_region

      # variables
      attacker_context_config_protonvpn_user               = var.attacker_context_config_protonvpn_user
      attacker_context_config_protonvpn_password           = var.attacker_context_config_protonvpn_password
      attacker_context_config_protonvpn_tier               = var.attacker_context_config_protonvpn_tier
      attacker_context_cloud_cryptomining_ethermine_wallet = var.attacker_context_cloud_cryptomining_ethermine_wallet
      attacker_context_host_cryptomining_minergate_user    = var.attacker_context_host_cryptomining_minergate_user
      attacker_context_host_cryptomining_nicehash_user     = var.attacker_context_host_cryptomining_nicehash_user
    }
  )
  attacker_attacksimulation_temp_config = jsondecode(local.attacker-attacksimulation-config-file)
  target_attacksimulation_temp_config   = jsondecode(local.target-attacksimulation-config-file)
  attacker_attacksimulation_override    = {}
  target_attacksimulation_override      = {}
}

data "utils_deep_merge_json" "attacker-attacksimulation-config" {
  input = [
    jsonencode(module.default-attacksimulation-context.config),
    local.attacker-attacksimulation-config-file,
    jsonencode(local.attacker_attacksimulation_override)
  ]
}

data "utils_deep_merge_json" "target-attacksimulation-config" {
  input = [
    jsonencode(module.default-attacksimulation-context.config),
    local.target-attacksimulation-config-file,
    jsonencode(local.target_attacksimulation_override)
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
    module.attacker-aws-infrastructure.id,
    module.target-aws-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # surface
    module.attacker-aws-attacksurface.id,
    module.target-aws-attacksurface.id,

    # config destory delay
    # time_sleep.wait_120_seconds.id
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
    module.attacker-aws-infrastructure.id,
    module.target-aws-infrastructure.id,

    # surface context
    module.attacker-attacksurface-context.id,
    module.target-attacksurface-context.id,

    # surface
    module.attacker-aws-attacksurface.id,
    module.target-aws-attacksurface.id,

    # config destory delay
    # time_sleep.wait_120_seconds.id
  ]
}