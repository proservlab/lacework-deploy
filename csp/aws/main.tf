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

#########################
# CONFIG
########################

module "attacker-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-infrastructure-context.config,
    {
      context = {
        global = {
          environment          = "attacker"
          trust_security_group = true
        }
        aws = {
          profile_name = var.attacker_aws_profile
          ec2 = {
            enabled            = true
            public_network     = "172.27.0.0/16"
            public_subnet      = "172.27.0.0/24"
            private_network    = "172.26.0.0/16"
            private_subnet     = "172.26.100.0/24"
            private_nat_subnet = "172.26.10.0/24"
            instances = [
              {
                name                      = "attacker-public-1"
                public                    = true
                instance_type             = "t2.micro"
                ami_name                  = "ubuntu_focal"
                enable_ssm_console_access = true
                tags                      = {}
                user_data                 = null
                user_data_base64          = null
              }
            ]
          }
          eks = {
            enabled      = false
            cluster_name = "attacker-cluster"
          }
        }
      }
    }
  ]
}

module "target-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-infrastructure-context.config,
    {
      context = {
        global = {
          environment          = "target"
          trust_security_group = true
        }
        aws = {
          profile_name = var.target_aws_profile
          ec2 = {
            enabled            = true
            public_network     = "172.17.0.0/16"
            public_subnet      = "172.17.0.0/24"
            private_network    = "172.16.0.0/16"
            private_subnet     = "172.16.100.0/24"
            private_nat_subnet = "172.16.10.0/24"
            instances = [
              {
                name                      = "target-public-1"
                public                    = true
                instance_type             = "t2.micro"
                ami_name                  = "ubuntu_focal"
                enable_ssm_console_access = true
                tags = {
                  ssm_deploy_lacework              = "true"
                  ssm_deploy_docker                = "true"
                  ssm_deploy_secret_ssh_private    = "true"
                  ssm_exec_docker_log4shell_target = "true"
                }
                user_data        = null
                user_data_base64 = null
              },
              {
                name                      = "target-public-2"
                public                    = true
                instance_type             = "t2.micro"
                ami_name                  = "ubuntu_focal"
                enable_ssm_console_access = true
                tags = {
                  ssm_deploy_lacework          = "true"
                  ssm_deploy_secret_ssh_public = "true"
                }
                user_data        = null
                user_data_base64 = null
              }
            ]
          }
          eks = {
            enabled      = true
            cluster_name = "target-cluster"
          }
          ssm = {
            enabled                        = true
            deploy_git                     = true
            deploy_docker                  = true
            deploy_inspector_agent         = true
            deploy_lacework_agent          = true
            deploy_lacework_syscall_config = true
          }
        }
        lacework = {
          server_url   = var.lacework_server_url
          account_name = var.lacework_account_name
          aws_audit_config = {
            enabled = true
          }
          gcp_audit_config = {
            project_id = var.target_gcp_lacework_project
            enabled    = true
          }
          custom_policy = {
            enabled = true
          }
          agent = {
            enabled = true

            kubernetes = {
              enabled = true
              proxy_scanner = {
                token   = var.lacework_proxy_token
                enabled = true
              }
              daemonset = {
                enabled        = true
                syscall_config = <<-EOT
                                  etype.exec:
                                  etype.initmod:
                                  etype.finitmod:
                                  etype.exit:
                                  etype.file:
                                      send-if-matches:
                                          ubuntu-authorized-keys:
                                              watchpath: /home/*/.ssh/authorized_keys
                                              watchfor: create, modify
                                          root-authorized-keys:
                                              watchpath: /root/.ssh/authorized_keys
                                              watchfor: create, modify
                                          cronfiles:
                                              watchpath: /etc/cron*
                                              depth: 2
                                          systemd:
                                              watchpath: /etc/systemd/*
                                              depth: 2
                                          boot-initd:
                                              watchpath: /etc/init.d/*
                                              depth: 2
                                          boot-rc:
                                              watchpath: /etc/rc*
                                              depth: 2
                                          shadow-file:
                                              watchpath: /etc/shadow*
                                          watchlacework:
                                              watchpath: /var/lib/lacework
                                              depth: 2
                                          watchpasswd:
                                              watchpath: /etc/passwd
                                  EOT
              }
              compliance = {
                enabled = true
              }
              eks_audit_logs = {
                enabled = true
              }
              admission_controller = {
                enabled = true
              }
            }
          }
          aws_agentless = {
            enabled = true
          }
          gcp_agentless = {
            enabled = false
          }
          alerts = {
            enabled = true
            slack = {
              enabled   = true
              api_token = var.slack_token
            }
            jira = {
              enabled           = true
              cloud_url         = var.jira_cloud_url
              cloud_username    = var.jira_cloud_username
              cloud_api_token   = var.jira_cloud_api_token
              cloud_project_key = var.jira_cloud_project_key
              cloud_issue_type  = var.jira_cloud_issue_type
            }
          }
        }
      }
    }
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

module "target-attacksurface-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    module.default-attacksurface-context.config,
    {
      context = {
        aws = {
          iam = {
            enabled = true
            user_policies = {
              "simulation_power_user" = jsonencode({
                "Version" : "2012-10-17",
                "Statement" : [
                  {
                    "Sid" : "AllowSpecifics",
                    "Action" : [
                      "lambda:*",
                      "apigateway:*",
                      "ec2:*",
                      "rds:*",
                      "s3:*",
                      "sns:*",
                      "states:*",
                      "ssm:*",
                      "sqs:*",
                      "iam:*",
                      "elasticloadbalancing:*",
                      "autoscaling:*",
                      "cloudwatch:*",
                      "cloudfront:*",
                      "route53:*",
                      "ecr:*",
                      "logs:*",
                      "ecs:*",
                      "application-autoscaling:*",
                      "logs:*",
                      "events:*",
                      "elasticache:*",
                      "es:*",
                      "kms:*",
                      "dynamodb:*",
                      "fms:*",
                      "guardduty:*",
                      "inspector:*",
                      "waf:*"
                    ],
                    "Effect" : "Allow",
                    "Resource" : "*"
                  },
                  {
                    "Sid" : "DenySpecifics",
                    "Action" : [
                      "iam:*User*",
                      "iam:*Login*",
                      "iam:*Group*",
                      "iam:*Provider*",
                      "aws-portal:*",
                      "budgets:*",
                      "config:*",
                      "directconnect:*",
                      "aws-marketplace:*",
                      "aws-marketplace-management:*",
                      "ec2:*ReservedInstances*"
                    ],
                    "Effect" : "Deny",
                    "Resource" : "*"
                  }
                ]
              })
            }
            users = [
              {
                name   = "claude.kripto@interlacelabs"
                policy = "simulation_power_user"
              },
              {
                name   = "dee.fensivason@interlacelabs"
                policy = "simulation_power_user"
              },
              {
                name   = "haust.kripto@interlacelabs"
                policy = "simulation_power_user"
              },
              {
                name   = "kees.kompromize@interlacelabs"
                policy = "simulation_power_user"
              },
              {
                name   = "rand.sumwer@interlacelabs"
                policy = "simulation_power_user"
              },

              {
                name   = "clue.burnetes@interlacelabs"
                policy = "simulation_power_user"
              },
            ]
          }
          rds = {
            enabled                = true
            igw_id                 = module.target-infrastructure.config.context.aws.ec2[0].public_igw.id
            vpc_id                 = module.target-infrastructure.config.context.aws.ec2[0].public_vpc.id
            vpc_subnet             = module.target-infrastructure.config.context.aws.ec2[0].public_network
            ec2_instance_role_name = module.target-infrastructure.config.context.aws.ec2[0].ec2_instance_role.name
            trusted_sg_id          = module.target-infrastructure.config.context.aws.ec2[0].public_sg.id
            root_db_username       = "dbuser"
            root_db_password       = "dbpassword"
          }
          ssm = {
            log4j = {
              enabled = true
            }
            ssh_keys = {
              enabled = true
            }
          }
        }
        kubernetes = {
          app = {
            enabled = true
          }
          psp = {
            enabled = false
          }
          vulnerable = {
            log4j = {
              enabled = true
            }
            voteapp = {
              enabled = true
            }

            rdsapp = {
              enabled = true
            }
            privileged_pod = {
              enabled = false
            }
            root_mount_fs_pod = {
              enabled = false
            }
          }
        }
      }
    }
  ]
}

#########################
# ATTACK SURFACE CONTEXT
########################

# set attack the context
module "target-attacksurface-context" {
  source = "./modules/context/attack/surface"
  config = module.target-attacksurface-config.merged
}

#########################
# ATTACK SURFACE DEPLOYMENT
########################

# deploy attacksurface
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
                  enabled = false
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
  source = "./modules/context/attack/exec"
  config = module.target-attacksimulation-config.merged
}

#########################
# ATTACKSIMULATION DEPLOYMENT
########################

# deploy target attacksimulation
module "target-attacksimulation" {
  source = "./modules/attack/exec"
  # attack surface config
  config = module.target-attacksimulation-context.config

  # infrasturcture config and deployed state
  infrastructure = {
    # initial configuration reference
    config = {
      target   = module.target-infrastructure-context.config
      attacker = module.attacker-infrastructure-context.config
    }
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