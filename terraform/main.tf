#########################
# DEFAULT
########################

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

#########################
# INFRASTRUCTURE CONFIG
########################

data "template_file" "attacker-infrastructure-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/attacker/infrastructure.json")
  vars = {
    # deployment id
    deployment = module.deployment.id

    # aws
    aws_profile = var.attacker_aws_profile
  }
}

data "template_file" "target-infrastructure-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/target/infrastructure.json")
  vars = {
    # deployment id
    deployment = module.deployment.id

    # aws
    aws_profile = var.target_aws_profile

    # gcp
    gcp_lacework_project = var.target_gcp_lacework_project

    # lacework
    lacework_server_url   = var.lacework_server_url
    lacework_account_name = var.lacework_account_name
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


#########################
# INFRASTRUCTURE CONTEXT
########################

# set infrasturcture context
module "attacker-infrastructure-context" {
  source = "./modules/context/infrastructure"
  config = jsondecode(data.utils_deep_merge_json.attacker-infrastructure-config.output)
}

module "target-infrastructure-context" {
  source = "./modules/context/infrastructure"
  config = jsondecode(data.utils_deep_merge_json.target-infrastructure-config.output)
}

#########################
# INFRASTRUCTURE DEPLOYMENT
########################

# deploy infrastructure
module "attacker-infrastructure" {
  source = "./modules/infrastructure"
  config = module.attacker-infrastructure-context.config

  providers = {
    aws      = aws.attacker
    lacework = lacework.attacker
  }
}

module "target-infrastructure" {
  source = "./modules/infrastructure"
  config = module.target-infrastructure-context.config

  providers = {
    aws      = aws.target
    lacework = lacework.target
  }
}

#########################
# ATTACK SURFACE CONFIG
########################

data "template_file" "attacker-attacksurface-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/attacker/surface.json")

  vars = {
    # ec2 security group trusted ingress
    security_group_id = try(module.attacker-infrastructure.config.context.aws.ec2[0].public_sg.id, "")
  }
}

data "template_file" "target-attacksurface-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/target/surface.json")

  vars = {
    # iam
    iam_power_user_policy_path = abspath("${path.module}/scenarios/${var.scenario}/target/resources/iam_power_user_policy.json")
    iam_users_path             = abspath("${path.module}/scenarios/${var.scenario}/target/resources/iam_users.json")

    # ec2 security group trusted ingress
    security_group_id = try(module.target-infrastructure.config.context.aws.ec2[0].public_sg.id, "")

    # rds
    rds_igw_id                 = try(module.target-infrastructure.config.context.aws.ec2[0].public_app_igw.id, "")
    rds_vpc_id                 = try(module.target-infrastructure.config.context.aws.ec2[0].public_app_vpc.id, "")
    rds_vpc_subnet             = try(module.target-infrastructure.config.context.aws.ec2[0].public_app_network, "")
    rds_ec2_instance_role_name = try(module.target-infrastructure.config.context.aws.ec2[0].ec2_instance_app_role.name, "")
    rds_trusted_sg_id          = try(module.target-infrastructure.config.context.aws.ec2[0].public_app_sg.id, "")
    rds_root_db_username       = "dbuser"
    rds_root_db_password       = "dbpassword"
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

#########################
# ATTACK SURFACE CONTEXT
########################

# set attack the context
module "attacker-attacksurface-context" {
  source = "./modules/context/attack/surface"
  config = jsondecode(data.utils_deep_merge_json.attacker-attacksurface-config.output)
}

module "target-attacksurface-context" {
  source = "./modules/context/attack/surface"
  config = jsondecode(data.utils_deep_merge_json.target-attacksurface-config.output)
}

#########################
# ATTACK SURFACE DEPLOYMENT
########################

# deploy attacksurface
module "attacker-attacksurface" {
  source = "./modules/attack/surface"
  # attack surface config
  config = module.attacker-attacksurface-context.config

  # infrasturcture config and deployed state
  infrastructure = {
    # initial configuration reference
    config = module.attacker-infrastructure-context.config
    # deployed state configuration reference
    deployed_state = {
      target   = module.target-infrastructure.config
      attacker = module.attacker-infrastructure.config
    }
  }

  kubeconfig_path = try(module.attacker-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")

  providers = {
    aws      = aws.attacker
    lacework = lacework.attacker
  }
}

module "target-attacksurface" {
  source = "./modules/attack/surface"
  # attack surface config
  config = module.target-attacksurface-context.config

  # infrasturcture config and deployed state
  infrastructure = {
    # initial configuration reference
    config = module.target-infrastructure-context.config
    # deployed state configuration reference
    deployed_state = {
      target   = module.target-infrastructure.config
      attacker = module.attacker-infrastructure.config
    }
  }

  kubeconfig_path = try(module.target-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")

  providers = {
    aws      = aws.target
    lacework = lacework.target
  }
}

#########################
# ATTACKSIMULATION CONFIG
########################

data "template_file" "attacker-attacksimulation-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/attacker/simulation.json")

  vars = {}
}

data "template_file" "target-attacksimulation-config-file" {
  template = file("${path.module}/scenarios/${var.scenario}/target/simulation.json")

  vars = {}
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

#########################
# ATTACKSIMULATION CONTEXT
########################

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

#########################
# ATTACKSIMULATION DEPLOYMENT
########################

# deploy target attacksimulation
module "attacker-attacksimulation" {
  source = "./modules/attack/simulate"
  # attack surface config
  config = module.attacker-attacksimulation-context.config

  # infrasturcture config and deployed state
  infrastructure = {
    # initial configuration reference
    config = module.attacker-infrastructure-context.config

    # deployed state configuration reference
    deployed_state = {
      target   = module.target-infrastructure.config
      attacker = module.attacker-infrastructure.config
    }
  }

  kubeconfig_path = try(module.attacker-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")

  providers = {
    aws      = aws.attacker
    lacework = lacework.attacker
  }
}

# deploy target attacksimulation
module "target-attacksimulation" {
  source = "./modules/attack/simulate"
  # attack surface config
  config = module.target-attacksimulation-context.config

  # infrasturcture config and deployed state
  infrastructure = {
    # initial configuration reference
    config = module.target-infrastructure-context.config

    # deployed state configuration reference
    deployed_state = {
      target   = module.target-infrastructure.config
      attacker = module.attacker-infrastructure.config
    }
  }

  kubeconfig_path = try(module.target-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")

  providers = {
    aws      = aws.target
    lacework = lacework.target
  }
}