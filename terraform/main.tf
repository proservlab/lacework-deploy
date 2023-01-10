#########################
# DEFAULT
########################

# defaults
module "defaults" {
  source = "./modules/context/tags"
}

module "default-ssm-tags" {
  source = "./modules/context/tags"
}

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
# CONFIG
########################

data "template_file" "attack-config-file" {
  template = file("${path.module}/scenarios/simple/attacker/infrastructure.json")
  vars = {
    attacker_aws_profile = var.attacker_aws_profile
  }
}

module "attacker-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-infrastructure-context.config,
    jsondecode(data.template_file.attack-config-file.rendered)
  ]
}

data "template_file" "target-config-file" {
  template = file("${path.module}/scenarios/simple/target/infrastructure.json")
  vars = {
    # aws
    target_aws_profile = var.target_aws_profile

    # lacework
    lacework_server_url   = var.lacework_server_url
    lacework_account_name = var.lacework_account_name
    syscall_config_path   = abspath("${path.module}/scenarios/simple/target/resources/syscall_config.yaml")
  }
}

module "target-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-infrastructure-context.config,
    jsondecode(data.template_file.target-config-file.rendered)
  ]
}


#########################
# INFRASTRUCTURE CONTEXT
########################

# set infrasturcture context
module "attacker-infrastructure-context" {
  source = "./modules/context/infrastructure"
  config = module.attacker-config.merged
}

module "target-infrastructure-context" {
  source = "./modules/context/infrastructure"
  config = module.target-config.merged
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
    google   = google.attacker
    lacework = lacework.attacker
  }
}

module "target-infrastructure" {
  source = "./modules/infrastructure"
  config = module.target-infrastructure-context.config

  providers = {
    aws      = aws.target
    google   = google.target
    lacework = lacework.target
  }
}

#########################
# ATTACK SURFACE CONFIG
########################

data "template_file" "attacker-attacksurface-config-file" {
  template = file("${path.module}/scenarios/simple/attacker/surface.json")

  vars = {
    # ec2 security group trusted ingress
    security_group_id = module.attacker-infrastructure.config.context.aws.ec2[0].public_sg.id
  }
}
module "attacker-attacksurface-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-attacksurface-context.config,
    jsondecode(data.template_file.attacker-attacksurface-config-file.rendered)
  ]
}

data "template_file" "target-attacksurface-config-file" {
  template = file("${path.module}/scenarios/simple/target/surface.json")

  vars = {
    # ec2 security group trusted ingress
    security_group_id = module.target-infrastructure.config.context.aws.ec2[0].public_sg.id
  }
}

module "target-attacksurface-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-attacksurface-context.config,
    jsondecode(data.template_file.target-attacksurface-config-file.rendered)
  ]
}

#########################
# ATTACK SURFACE CONTEXT
########################

# set attack the context
module "attacker-attacksurface-context" {
  source = "./modules/context/attack/surface"
  config = module.attacker-attacksurface-config.merged
}

module "target-attacksurface-context" {
  source = "./modules/context/attack/surface"
  config = module.target-attacksurface-config.merged
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
  providers = {
    aws        = aws.attacker
    lacework   = lacework.attacker
    kubernetes = kubernetes.attacker
    helm       = helm.attacker
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
  providers = {
    aws        = aws.target
    lacework   = lacework.target
    kubernetes = kubernetes.target
    helm       = helm.target
  }
}

#########################
# ATTACKSIMULATION CONFIG
########################

data "template_file" "attacker-attacksimulation-config-file" {
  template = file("${path.module}/scenarios/simple/attacker/simulation.json")

  vars = {}
}

module "attacker-attacksimulation-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-attacksimulation-context.config,
    jsondecode(data.template_file.attacker-attacksimulation-config-file.rendered)
  ]
}

data "template_file" "target-attacksimulation-config-file" {
  template = file("${path.module}/scenarios/simple/target/simulation.json")

  vars = {}
}

module "target-attacksimulation-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-attacksimulation-context.config,
    jsondecode(data.template_file.target-attacksimulation-config-file.rendered)
  ]
}

#########################
# ATTACKSIMULATION CONTEXT
########################

# set attack the context
module "attacker-attacksimulation-context" {
  source = "./modules/context/attack/simulate"
  config = module.attacker-attacksimulation-config.merged
}

# set attack the context
module "target-attacksimulation-context" {
  source = "./modules/context/attack/simulate"
  config = module.target-attacksimulation-config.merged
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
  providers = {
    aws        = aws.attacker
    lacework   = lacework.attacker
    kubernetes = kubernetes.attacker
    helm       = helm.attacker
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
  providers = {
    aws        = aws.target
    lacework   = lacework.target
    kubernetes = kubernetes.target
    helm       = helm.target
  }
}