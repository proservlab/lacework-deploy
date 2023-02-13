##################################################
# DEFAULT
##################################################

# unique id used for deployment
module "deployment" {
  source = "./modules/context/deployment"
}

# defaults
module "default-infrastructure-context" {
  source = "./modules/context/infrastructure"
}

module "default-attacksurface-context" {
  source = "./modules/context/attack/surface"
}

module "default-attacksimulation-context" {
  source = "./modules/context/attack/simulate"
}

##################################################
# KUBECONFIG STAGING
##################################################

locals {
  kubeconfigs = [
    pathexpand("~/.kube/aws-attacker-${var.deployment}-kubeconfig"),
    pathexpand("~/.kube/aws-target-${var.deployment}-kubeconfig"),
    pathexpand("~/.kube/gcp-attacker-${var.deployment}-kubeconfig"),
    pathexpand("~/.kube/gcp-target-${var.deployment}-kubeconfig")
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

      # aws
      aws_profile = can(length(var.attacker_aws_profile)) ? var.attacker_aws_profile : ""
      aws_region  = var.attacker_aws_region

      # gcp
      gcp_project = var.attacker_gcp_project
      gcp_region  = var.attacker_gcp_region

      # lacework
      lacework_profile = var.lacework_profile
    }
  )
  target-infrastructure-config-file = templatefile(
    "${path.module}/scenarios/${var.scenario}/target/infrastructure.json",
    {
      # deployment id
      deployment = var.deployment

      # aws
      aws_profile = can(length(var.target_aws_profile)) ? var.target_aws_profile : ""
      aws_region  = var.target_aws_region

      # gcp
      gcp_project          = var.target_gcp_project
      gcp_region           = var.target_gcp_region
      gcp_lacework_project = var.target_gcp_lacework_project

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
  source = "./modules/context/infrastructure"
  config = jsondecode(data.utils_deep_merge_json.attacker-infrastructure-config.output)
}

module "target-infrastructure-context" {
  source = "./modules/context/infrastructure"
  config = jsondecode(data.utils_deep_merge_json.target-infrastructure-config.output)
}

##################################################
# INFRASTRUCTURE DEPLOYMENT
##################################################

# deploy infrastructure
module "attacker-aws-infrastructure" {
  source = "./modules/infrastructure/aws"
  config = module.attacker-infrastructure-context.config
}

module "attacker-gcp-infrastructure" {
  source = "./modules/infrastructure/gcp"
  config = module.attacker-infrastructure-context.config
}

module "target-aws-infrastructure" {
  source = "./modules/infrastructure/aws"
  config = module.target-infrastructure-context.config
}

module "target-gcp-infrastructure" {
  source = "./modules/infrastructure/gcp"
  config = module.target-infrastructure-context.config
}

##################################################
# INFRASTRUCTURE LACEWORK DEPLOYMENT
#
# Note: Lacework Kubernetes Modules Require EKS/GKE
##################################################

module "attacker-lacework-platform-infrastructure" {
  source = "./modules/infrastructure/lacework/platform"
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
      aws = {
        target   = try(module.target-aws-infrastructure.config, {})
        attacker = try(module.attacker-aws-infrastructure.config, {})
      }
      gcp = {
        target   = try(module.target-gcp-infrastructure.config, {})
        attacker = try(module.attacker-gcp-infrastructure.config, {})
      }
    }
  }
}

module "attacker-lacework-aws-infrastructure" {
  source = "./modules/infrastructure/lacework/aws"
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
      target   = try(module.target-aws-infrastructure.config, {})
      attacker = try(module.attacker-aws-infrastructure.config, {})
    }
  }
}

module "attacker-lacework-gcp-infrastructure" {
  source = "./modules/infrastructure/lacework/gcp"
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
}

module "target-lacework-platform-infrastructure" {
  source = "./modules/infrastructure/lacework/platform"
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
      target   = module.target-aws-infrastructure.config
      attacker = module.attacker-aws-infrastructure.config
    }
  }
}

module "target-lacework-aws-infrastructure" {
  source = "./modules/infrastructure/lacework/aws"
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
      target   = try(module.target-aws-infrastructure.config, {})
      attacker = try(module.attacker-aws-infrastructure.config, {})
    }
  }
}

module "target-lacework-gcp-infrastructure" {
  source = "./modules/infrastructure/lacework/gcp"
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
}

##################################################
# INFRASTRUCTURE DYNU DNS
##################################################

locals {
  target_aws_a_records = [
    for ec2 in can(length(module.target-aws-infrastructure.config.context.aws.ec2)) ? module.target-aws-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : {
        recordType     = "a"
        recordName     = "${lookup(compute.instance.tags, "Name", "unknown")}"
        recordHostName = "${lookup(compute.instance.tags, "Name", "unknown")}.${var.dynu_dns_domain}"
        recordValue    = compute.instance.public_ip
      } if lookup(compute.instance, "public_ip", "false") != "false"
    ]
  ]
  attacker_aws_a_records = [
    for ec2 in can(length(module.attacker-aws-infrastructure.config.context.aws.ec2)) ? module.attacker-aws-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : {
        recordType     = "a"
        recordName     = "${lookup(compute.instance.tags, "Name", "unknown")}"
        recordHostName = "${lookup(compute.instance.tags, "Name", "unknown")}.${var.dynu_dns_domain}"
        recordValue    = compute.instance.public_ip
      } if lookup(compute.instance, "public_ip", "false") != "false"
    ]
  ]

  target_gcp_a_records = [
    for gce in can(length(module.target-gcp-infrastructure.config.context.gcp.gce)) ? module.target-gcp-infrastructure.config.context.gcp.gce : [] :
    [
      for compute in gce.instances : {
        recordType     = "a"
        recordName     = "${lookup(compute.instance.labels, "name", "unknown")}"
        recordHostName = "${lookup(compute.instance.labels, "name", "unknown")}.${var.dynu_dns_domain}"
        recordValue    = compute.instance.network_interface[0].access_config[0].nat_ip
      } if lookup(try(compute.instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
    ]
  ]
  attacker_gcp_a_records = [
    for gce in can(length(module.attacker-gcp-infrastructure.config.context.gcp.gce)) ? module.attacker-gcp-infrastructure.config.context.gcp.gce : [] :
    [
      for compute in gce.instances : {
        recordType     = "a"
        recordName     = "${lookup(compute.instance.labels, "name", "unknown")}"
        recordHostName = "${lookup(compute.instance.labels, "name", "unknown")}.${var.dynu_dns_domain}"
        recordValue    = compute.instance.network_interface[0].access_config[0].nat_ip
      } if lookup(try(compute.instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
    ]
  ]

  # kubernetes service mapping
  # cname_records =  [
  #   for eks in can(length(module.target-infrastructure.config.context.aws.eks)) ? module.target-infrastructure.config.context.aws.eks : [] :
  #   [
  #     {
  #       recordType="cname"
  #       recordName=eks.cluster_name
  #       recordValue=eks.cluster_nat_public_ip
  #     } if lookup(compute.instance, "public_ip", "false") != "false"
  #   ]
  # ]
}

module "target-dynu-dns-records" {
  source = "./modules/infrastructure/dynu"
  config = module.target-infrastructure-context.config

  dynu_api_token  = var.dynu_api_token
  dynu_dns_domain = var.dynu_dns_domain
  records = flatten([
    local.target_aws_a_records,
    local.target_gcp_a_records
  ])
}

module "attacker-dynu-dns-records" {
  source = "./modules/infrastructure/dynu"
  config = module.attacker-infrastructure-context.config

  dynu_api_token  = var.dynu_api_token
  dynu_dns_domain = var.dynu_dns_domain
  records = flatten([
    local.attacker_aws_a_records,
    local.attacker_gcp_a_records
  ])
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
  source = "./modules/context/attack/surface"
  config = jsondecode(data.utils_deep_merge_json.attacker-attacksurface-config.output)
}

module "target-attacksurface-context" {
  source = "./modules/context/attack/surface"
  config = jsondecode(data.utils_deep_merge_json.target-attacksurface-config.output)
}

##################################################
# ATTACK SURFACE DEPLOYMENT
##################################################

# deploy attacksurface
module "attacker-aws-attacksurface" {
  source = "./modules/attack/surface/aws"
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
      target   = try(module.target-aws-infrastructure.config, {})
      attacker = try(module.attacker-aws-infrastructure.config, {})
    }
  }
}

module "attacker-gcp-attacksurface" {
  source = "./modules/attack/surface/gcp"
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
}

module "target-aws-attacksurface" {
  source = "./modules/attack/surface/aws"

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
      target   = try(module.target-aws-infrastructure.config, {})
      attacker = try(module.attacker-aws-infrastructure.config, {})
    }
  }
}

module "target-gcp-attacksurface" {
  source = "./modules/attack/surface/gcp"

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

      # gcp
      attacker_gcp_project        = var.attacker_gcp_project
      attacker_gcp_region         = var.attacker_gcp_region
      target_gcp_project          = var.target_gcp_project
      target_gcp_region           = var.target_gcp_region
      target_gcp_lacework_project = var.target_gcp_lacework_project

      # variables
      compromised_credentials                              = abspath("${path.module}/scenarios/${var.scenario}/target/resources/iam_users.json")
      attacker_context_config_protonvpn_user               = var.attacker_context_config_protonvpn_user
      attacker_context_config_protonvpn_password           = var.attacker_context_config_protonvpn_password
      attacker_context_cloud_cryptomining_ethermine_wallet = var.attacker_context_cloud_cryptomining_ethermine_wallet
      attacker_context_host_cryptomining_minergate_user    = var.attacker_context_host_cryptomining_minergate_user
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

      # gcp
      attacker_gcp_project        = var.attacker_gcp_project
      attacker_gcp_region         = var.attacker_gcp_region
      target_gcp_project          = var.target_gcp_project
      target_gcp_region           = var.target_gcp_region
      target_gcp_lacework_project = var.target_gcp_lacework_project

      # variables
      attacker_context_config_protonvpn_user               = var.attacker_context_config_protonvpn_user
      attacker_context_config_protonvpn_password           = var.attacker_context_config_protonvpn_password
      attacker_context_cloud_cryptomining_ethermine_wallet = var.attacker_context_cloud_cryptomining_ethermine_wallet
      attacker_context_host_cryptomining_minergate_user    = var.attacker_context_host_cryptomining_minergate_user
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
  source = "./modules/context/attack/simulate"
  config = jsondecode(data.utils_deep_merge_json.attacker-attacksimulation-config.output)
}

# set attack the context
module "target-attacksimulation-context" {
  source = "./modules/context/attack/simulate"
  config = jsondecode(data.utils_deep_merge_json.target-attacksimulation-config.output)
}

##################################################
# ATTACKSIMULATION DEPLOYMENT
##################################################

# deploy target attacksimulation
module "attacker-aws-attacksimulation" {
  source = "./modules/attack/simulate/aws"
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
}

# deploy target attacksimulation
module "attacker-gcp-attacksimulation" {
  source = "./modules/attack/simulate/gcp"
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
}

# deploy target attacksimulation
module "target-aws-attacksimulation" {
  source = "./modules/attack/simulate/aws"
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
}

# deploy target attacksimulation
module "target-gcp-attacksimulation" {
  source = "./modules/attack/simulate/gcp"
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
}