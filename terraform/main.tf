#########################
# DEFAULT
########################

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
  template = file("${path.module}/scenarios/simple/attacker/infrastructure.json")
  vars = {
    attacker_aws_profile = var.attacker_aws_profile
  }
}

module "attacker-infrastructure-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-infrastructure-context.config,
    jsondecode(data.template_file.attacker-infrastructure-config-file.rendered)
  ]
}

data "template_file" "target-infrastructure-config-file" {
  template = file("${path.module}/scenarios/simple/target/infrastructure.json")
  vars = {
    # aws
    target_aws_profile = var.target_aws_profile
  }
}

module "target-infrastructure-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-infrastructure-context.config,
    jsondecode(data.template_file.target-infrastructure-config-file.rendered)
  ]
}


#########################
# INFRASTRUCTURE CONTEXT
########################

# set infrasturcture context
module "attacker-infrastructure-context" {
  source = "./modules/context/infrastructure"
  config = module.attacker-infrastructure-config.merged
}

module "target-infrastructure-context" {
  source = "./modules/context/infrastructure"
  config = module.target-infrastructure-config.merged
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
  }
}

module "target-infrastructure" {
  source = "./modules/infrastructure"
  config = module.target-infrastructure-context.config

  providers = {
    aws      = aws.target
  }
}

#########################
# ATTACK SURFACE CONFIG
########################

data "template_file" "attacker-attacksurface-config-file" {
  template = file("${path.module}/scenarios/simple/attacker/surface.json")

  vars = {
    # ec2 security group trusted ingress
    security_group_id = try(module.attacker-infrastructure.config.context.aws.ec2[0].public_sg.id, "")
  }
}

data "template_file" "target-attacksurface-config-file" {
  template = file("${path.module}/scenarios/simple/target/surface.json")

  vars = {
    # ec2 security group trusted ingress
    security_group_id = try(module.target-infrastructure.config.context.aws.ec2[0].public_sg.id, "")
  }
}

locals {
  attacker_config = data.template_file.attacker-attacksurface-config-file.rendered
  target_config = data.template_file.target-attacksurface-config-file.rendered
}

data "utils_deep_merge_json" "attacker-attacksurface-config" {
  input = [
    jsonencode(module.default-attacksurface-context.config),
    local.attacker_config
  ]
}

data "utils_deep_merge_json" "target-attacksurface-config" {
  input = [
    jsonencode(module.default-attacksurface-context.config),
    local.target_config
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
  
  providers = {
    aws      = aws.attacker
    lacework = lacework.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
  }

  depends_on = [
    module.target-infrastructure,
    module.attacker-infrastructure,
    module.attacker-infrastructure-context,
    module.attacker-attacksurface-context
  ]
}

module "target-attacksurface" {
  source = "./modules/attack/surface"
  # attack surface config
  config = module.attacker-attacksurface-context.config

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
    aws      = aws.target
    lacework = lacework.target
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-infrastructure,
    module.attacker-infrastructure,
    module.target-infrastructure-context,
    module.target-attacksurface-context
  ]
}

# #########################
# # ATTACKSIMULATION CONFIG
# ########################

# data "template_file" "attacker-attacksimulation-config-file" {
#   template = file("${path.module}/scenarios/demo/attacker/simulation.json")

#   vars = {}
# }

# module "attacker-attacksimulation-config" {
#   source  = "cloudposse/config/yaml//modules/deepmerge"
#   version = "0.2.0"

#   maps = [
#     module.default-attacksimulation-context.config,
#     jsondecode(data.template_file.attacker-attacksimulation-config-file.rendered)
#   ]
# }

# data "template_file" "target-attacksimulation-config-file" {
#   template = file("${path.module}/scenarios/demo/target/simulation.json")

#   vars = {}
# }

# module "target-attacksimulation-config" {
#   source  = "cloudposse/config/yaml//modules/deepmerge"
#   version = "0.2.0"

#   maps = [
#     module.default-attacksimulation-context.config,
#     jsondecode(data.template_file.target-attacksimulation-config-file.rendered)
#   ]
# }

# #########################
# # ATTACKSIMULATION CONTEXT
# ########################

# # set attack the context
# module "attacker-attacksimulation-context" {
#   source = "./modules/context/attack/simulate"
#   config = module.attacker-attacksimulation-config.merged
# }

# # set attack the context
# module "target-attacksimulation-context" {
#   source = "./modules/context/attack/simulate"
#   config = module.target-attacksimulation-config.merged
# }

# #########################
# # ATTACKSIMULATION DEPLOYMENT
# ########################

# # deploy target attacksimulation
# module "attacker-attacksimulation" {
#   source = "./modules/attack/simulate"
#   # attack surface config
#   config = module.attacker-attacksimulation-context.config

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
#   providers = {
#     aws      = aws.attacker
#     lacework = lacework.attacker
#   }
# }

# # deploy target attacksimulation
# module "target-attacksimulation" {
#   source = "./modules/attack/simulate"
#   # attack surface config
#   config = module.target-attacksimulation-context.config

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
#   providers = {
#     aws      = aws.target
#     lacework = lacework.target
#   }
# }