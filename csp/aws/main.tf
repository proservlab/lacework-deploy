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
  source = "./modules/context/attack/execute"
}

#########################
# CONFIG
########################

data "template_file" "attack-config-file" {
  template = file("${path.module}/scenarios/demo/attacker/infrastructure.json")
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
  template = file("${path.module}/scenarios/demo/target/infrastructure.json")
  vars = {
    # aws
    target_aws_profile = var.target_aws_profile

    # gcp
    target_gcp_lacework_project = var.target_gcp_lacework_project

    # lacework
    lacework_server_url   = var.lacework_server_url
    lacework_account_name = var.lacework_account_name
    syscall_config_path   = "${path.module}/scenarios/demo/target/resources/syscall_config.yaml"

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
  template = file("${path.module}/scenarios/demo/attacker/attacksurface.json")

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
  template = file("${path.module}/scenarios/demo/target/attacksurface.json")

  vars = {
    # iam
    iam_power_user_policy_path = "${path.module}/scenarios/demo/target/resources/iam_power_user_policy.json"
    iam_users_path             = "${path.module}/scenarios/demo/target/resources/iam_users.json"

    # ec2 security group trusted ingress
    security_group_id = module.target-infrastructure.config.context.aws.ec2[0].public_sg.id

    # rds
    rds_igw_id                 = module.target-infrastructure.config.context.aws.ec2[0].public_igw.id
    rds_vpc_id                 = module.target-infrastructure.config.context.aws.ec2[0].public_vpc.id
    rds_vpc_subnet             = module.target-infrastructure.config.context.aws.ec2[0].public_network
    rds_ec2_instance_role_name = module.target-infrastructure.config.context.aws.ec2[0].ec2_instance_role.name
    rds_trusted_sg_id          = module.target-infrastructure.config.context.aws.ec2[0].public_sg.id
    rds_root_db_username       = "dbuser"
    rds_root_db_password       = "dbpassword"
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
    aws        = aws.target
    lacework   = lacework.target
    kubernetes = kubernetes.target
    helm       = helm.target
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
module "attacker-attacksimulation-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-attacksimulation-context.config,
    {
      context = {
        simulation = {
          aws = {
            ssm = {
              listener = {
                http = {
                  enabled = false
                }
                port_forward = {
                  enabled = false
                }
              }
              responder = {
                reverse_shell = {
                  enabled = false
                }
                port_forward = {
                  enabled = false
                }
              }
              execute = {
                docker_log4shell_attack = {
                  enabled = false
                }
                docker_compromised_credentials_attack = {
                  enabled = false
                }
              }
            }
          }
        }
      }
    }
  ]
}

module "target-attacksimulation-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-attacksimulation-context.config,
    {
      context = {
        simulation = {
          aws = {
            ssm = {
              drop = {
                malware = {
                  eicar = {
                    enabled = false
                  }
                }
              }
              connect = {
                badip = {
                  enabled = false
                }
                nmap_port_scan = {
                  enabled = false
                }
                oast = {
                  enabled = true
                }
                codecov = {
                  enabled = false
                }
                reverse_shell = {
                  enabled = false
                }
              }
              listener = {
                http = {
                  enabled = false
                }
                port_forward = {
                  enabled = false
                }
              }
              execute = {
                docker_cpu_miner = {
                  enabled = false
                }
              }
            }
          }
        }
      }
    }
  ]
}

#########################
# ATTACKSIMULATION CONTEXT
########################

# set attack the context
module "target-attacksimulation-context" {
  source = "./modules/context/attack/execute"
  config = module.target-attacksimulation-config.merged
}

#########################
# ATTACKSIMULATION DEPLOYMENT
########################

# deploy target attacksimulation
module "target-attacksimulation" {
  source = "./modules/attack/execute"
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