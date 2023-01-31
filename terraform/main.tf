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
# INFRASTRUCTURE CONFIG
##################################################

data "template_file" "attacker-infrastructure-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/attacker/infrastructure.json")
  vars = {
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
}

data "template_file" "target-infrastructure-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/target/infrastructure.json")
  vars = {
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
}

locals {
  attacker_infrastructure_config = data.template_file.attacker-infrastructure-config-file.rendered
  target_infrastructure_config   = data.template_file.target-infrastructure-config-file.rendered
}

data "utils_deep_merge_json" "attacker-infrastructure-config" {
  input = [
    jsonencode(module.default-infrastructure-context.config),
    local.attacker_infrastructure_config
  ]
}

data "utils_deep_merge_json" "target-infrastructure-config" {
  input = [
    jsonencode(module.default-infrastructure-context.config),
    local.target_infrastructure_config
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
# KUBECONFIG STAGING
##################################################

# stage the kubeconfig files to avoid errors
resource "null_resource" "kubeconfig" {
  for_each = {
    aws_attacker_kubeconfig_path = pathexpand("~/.kube/aws-${module.attacker-infrastructure-context.config.context.global.environment}-${module.attacker-infrastructure-context.config.context.global.deployment}-kubeconfig")
    aws_target_kubeconfig_path   = pathexpand("~/.kube/aws-${module.target-infrastructure-context.config.context.global.environment}-${module.target-infrastructure-context.config.context.global.deployment}-kubeconfig")
    gcp_attacker_kubeconfig_path = pathexpand("~/.kube/gcp-${module.attacker-infrastructure-context.config.context.global.environment}-${module.attacker-infrastructure-context.config.context.global.deployment}-kubeconfig")
    gcp_target_kubeconfig_path   = pathexpand("~/.kube/gcp-${module.target-infrastructure-context.config.context.global.environment}-${module.target-infrastructure-context.config.context.global.deployment}-kubeconfig")
  }

  # stage kubeconfig
  provisioner "local-exec" {
    command = <<-EOT
              touch ${each.value}
              EOT
  }
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
      target   = module.target-aws-infrastructure.config
      attacker = module.attacker-aws-infrastructure.config
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
      target   = module.target-aws-infrastructure.config
      attacker = module.attacker-aws-infrastructure.config
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
      target   = module.target-aws-infrastructure.config
      attacker = module.attacker-aws-infrastructure.config
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
      target   = module.target-aws-infrastructure.config
      attacker = module.attacker-aws-infrastructure.config
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
      target   = module.target-aws-infrastructure.config
      attacker = module.attacker-aws-infrastructure.config
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
        recordName     = "${lookup(compute.instances.labels, "name", "unknown")}"
        recordHostName = "${lookup(compute.instances.labels, "name", "unknown")}.${var.dynu_dns_domain}"
        recordValue    = compute.instances.network_interface[0].access_config[0].nat_ip
      } if lookup(try(compute.instances.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
    ]
  ]
  attacker_gcp_a_records = [
    for gce in can(length(module.attacker-gcp-infrastructure.config.context.gcp.gce)) ? module.attacker-gcp-infrastructure.config.context.gcp.gce : [] :
    [
      for compute in gce.instances : {
        recordType     = "a"
        recordName     = "${lookup(compute.instances.labels, "name", "unknown")}"
        recordHostName = "${lookup(compute.instances.labels, "name", "unknown")}.${var.dynu_dns_domain}"
        recordValue    = compute.instances.network_interface[0].access_config[0].nat_ip
      } if lookup(try(compute.instances.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
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

data "template_file" "attacker-attacksurface-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/attacker/surface.json")

  vars = {
    # deployment id
    deployment = var.deployment
  }
}

data "template_file" "target-attacksurface-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/target/surface.json")

  vars = {
    # deployment id
    deployment = var.deployment

    # iam
    iam_power_user_policy_path = abspath("${path.module}/scenarios/${var.scenario}/target/resources/iam_power_user_policy.json")
    iam_users_path             = abspath("${path.module}/scenarios/${var.scenario}/target/resources/iam_users.json")
  }
}

locals {
  attacker_attacksurface_config = data.template_file.attacker-attacksurface-config-file.rendered
  target_attacksurface_config   = data.template_file.target-attacksurface-config-file.rendered
}

data "utils_deep_merge_json" "attacker-attacksurface-config" {
  input = [
    jsonencode(module.default-attacksurface-context.config),
    local.attacker_attacksurface_config
  ]
}

data "utils_deep_merge_json" "target-attacksurface-config" {
  input = [
    jsonencode(module.default-attacksurface-context.config),
    local.target_attacksurface_config
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

data "template_file" "attacker-attacksimulation-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/shared/simulation.json")

  vars = {
    # deployment id
    deployment = var.deployment

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
}

data "template_file" "target-attacksimulation-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/shared/simulation.json")

  vars = {
    # deployment id
    deployment = var.deployment

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
}

locals {
  attacker_attacksimulation_config = data.template_file.attacker-attacksimulation-config-file.rendered
  target_attacksimulation_config   = data.template_file.target-attacksimulation-config-file.rendered
}

data "utils_deep_merge_json" "attacker-attacksimulation-config" {
  input = [
    jsonencode(module.default-attacksimulation-context.config),
    local.attacker_attacksimulation_config
  ]
}

data "utils_deep_merge_json" "target-attacksimulation-config" {
  input = [
    jsonencode(module.default-attacksimulation-context.config),
    local.target_attacksimulation_config
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

# # deploy target attacksimulation
# module "attacker-attacksimulation" {
#   source = "./modules/attack/simulate"
#   # attack surface config
#   config = module.attacker-attacksimulation-context.config

#   attacker = true

#   # infrasturcture config and deployed state
#   infrastructure = {
#     # initial configuration reference
#     config = module.attacker-infrastructure-context.config

#     # deployed state configuration reference
#     deployed_state = {
#       target   = module.target-infrastructure.config
#       attacker = module.attacker-infrastructure.config
#     }
#   }

#   # compromised credentials (excluded from config to avoid dynamic dependancy...)
#   compromised_credentials = try(module.target-attacksurface.compromised_credentials, "")

#   # module providers config
#   kubeconfig_path      = try(module.attacker-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")
#   attacker_aws_profile = try(module.attacker-infrastructure-context.config.context.aws.profile_name,"")
#   target_aws_profile   = try(module.target-infrastructure-context.config.context.aws.profile_name,"")
# }

# # deploy target attacksimulation
# module "target-attacksimulation" {
#   source = "./modules/attack/simulate"
#   # attack surface config
#   config = module.target-attacksimulation-context.config

#   target = true

#   # infrasturcture config and deployed state
#   infrastructure = {
#     # initial configuration reference
#     config = module.target-infrastructure-context.config

#     # deployed state configuration reference
#     deployed_state = {
#       target   = module.target-infrastructure.config
#       attacker = module.attacker-infrastructure.config
#     }
#   }

#   # compromised credentials (excluded from config to avoid dynamic dependancy...)
#   compromised_credentials = try(module.target-attacksurface.compromised_credentials, "")

#   # module providers config
#   kubeconfig_path      = try(module.target-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")
#   attacker_aws_profile = try(module.attacker-infrastructure-context.config.context.aws.profile_name,"")
#   target_aws_profile   = try(module.target-infrastructure-context.config.context.aws.profile_name,"")
# }