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
# ATTACKSIMULATION DEPLOYMENT
########################

# deploy attacksimulation

# #########################
# # LOCALS
# #
# # instances - a list of all instances to create
# #             including ssm tag overrides
# #########################

# locals {
#   target = {
#     reverseshell = length(lookup(module.target, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_reverse_shell_target == "true"
#     ]) : []
#     log4shell = length(lookup(module.target, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_docker_log4shell_target == "true"
#     ]) : []
#     codecov = length(lookup(module.target, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_git_codecov_target == "true"
#     ]) : []
#     port_forward = length(lookup(module.target, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_port_forward_target == "true"
#     ]) : []
#     eks_public_ips = length(lookup(module.target, "eks_instances", [])) > 0 ? flatten([
#       for ip in lookup(module.target.eks_instances, "public_ips", []) : ip
#     ]) : []
#   }

#   attacker = {
#     http_listener = length(lookup(module.attacker, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_http_listener_attacker == "true"
#     ]) : []
#     reverseshell = length(lookup(module.attacker, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_reverse_shell_attacker == "true"
#     ]) : []
#     log4shell = length(lookup(module.attacker, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_docker_log4shell_attacker == "true"
#     ]) : []
#     port_forward = length(lookup(module.attacker, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_port_forward_attacker == "true"
#     ]) : []
#   }

#   attacker_instances = [
#     {
#       name           = "attacker-public-1"
#       public         = true
#       instance_type  = "t2.micro"
#       ami_name       = "ubuntu_focal"
#       enable_ssm     = true
#       ssm_deploy_tag = { ssm_deploy_lacework = "false" }
#       # override default ssm action tags
#       tags = merge(module.defaults.ssm_default_tags, {
#         ssm_deploy_docker                         = "true"
#         ssm_exec_docker_compromised_keys_attacker = "true"
#         #ssm_exec_reverse_shell_attacker = "true"
#       })
#       user_data        = null
#       user_data_base64 = null
#     },
#     # {
#     #   name           = "attacker-public-2"
#     #   public         = true
#     #   instance_type  = "t2.micro"
#     #   ami_name       = "ubuntu_focal"
#     #   enable_ssm     = true
#     #   ssm_deploy_tag = { ssm_deploy_lacework = "false" }
#     #   # override default ssm action tags
#     #   tags = merge(module.defaults.ssm_default_tags, {
#     #     ssm_deploy_docker                         = "true"
#     #     ssm_exec_docker_compromised_keys_attacker = "true"
#     #     ssm_exec_docker_log4shell_attacker        = "true"
#     #   })
#     #   user_data        = null
#     #   user_data_base64 = null
#     # },
#   ]

#   target_instances = [
#     {
#       name           = "target-public-1"
#       public         = true
#       instance_type  = "t2.micro"
#       ami_name       = "ubuntu_focal"
#       enable_ssm     = true
#       ssm_deploy_tag = { ssm_deploy_lacework = "true" }
#       # override default ssm action tags
#       tags = merge(module.defaults.ssm_default_tags, {
#         #ssm_deploy_docker             = "true"
#         #ssm_deploy_git                = "true"
#         ssm_deploy_secret_ssh_private = "true"
#         #ssm_exec_reverse_shell_target = "true"
#         #ssm_deploy_inspector_agent    = "true"
#       })

#       user_data        = null
#       user_data_base64 = null
#     },
#     {
#       name           = "target-public-2"
#       public         = true
#       instance_type  = "t2.micro"
#       ami_name       = "ubuntu_focal"
#       enable_ssm     = true
#       ssm_deploy_tag = { ssm_deploy_lacework = "true" }
#       # override default ssm action tags
#       tags = merge(module.defaults.ssm_default_tags, {
#         #ssm_deploy_docker                = "true"
#         ssm_deploy_secret_ssh_public = "true"
#         #ssm_exec_docker_log4shell_target = "true"
#       })
#       user_data        = null
#       user_data_base64 = null
#     },
#   ]

#   target_iam_policies = {
#     "simulation_power_user" = jsonencode({
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Sid" : "AllowSpecifics",
#           "Action" : [
#             "lambda:*",
#             "apigateway:*",
#             "ec2:*",
#             "rds:*",
#             "s3:*",
#             "sns:*",
#             "states:*",
#             "ssm:*",
#             "sqs:*",
#             "iam:*",
#             "elasticloadbalancing:*",
#             "autoscaling:*",
#             "cloudwatch:*",
#             "cloudfront:*",
#             "route53:*",
#             "ecr:*",
#             "logs:*",
#             "ecs:*",
#             "application-autoscaling:*",
#             "logs:*",
#             "events:*",
#             "elasticache:*",
#             "es:*",
#             "kms:*",
#             "dynamodb:*",
#             "fms:*",
#             "guardduty:*",
#             "inspector:*",
#             "waf:*"
#           ],
#           "Effect" : "Allow",
#           "Resource" : "*"
#         },
#         {
#           "Sid" : "DenySpecifics",
#           "Action" : [
#             "iam:*User*",
#             "iam:*Login*",
#             "iam:*Group*",
#             "iam:*Provider*",
#             "aws-portal:*",
#             "budgets:*",
#             "config:*",
#             "directconnect:*",
#             "aws-marketplace:*",
#             "aws-marketplace-management:*",
#             "ec2:*ReservedInstances*"
#           ],
#           "Effect" : "Deny",
#           "Resource" : "*"
#         }
#       ]
#     })
#   }

#   target_iam_users = [
#     {
#       name   = "claude.kripto@interlacelabs"
#       policy = local.target_iam_policies["simulation_power_user"]
#     },
#     {
#       name   = "dee.fensivason@interlacelabs"
#       policy = local.target_iam_policies["simulation_power_user"]
#     },
#     {
#       name   = "haust.kripto@interlacelabs"
#       policy = local.target_iam_policies["simulation_power_user"]
#     },
#     {
#       name   = "kees.kompromize@interlacelabs"
#       policy = local.target_iam_policies["simulation_power_user"]
#     },
#     {
#       name   = "rand.sumwer@interlacelabs"
#       policy = local.target_iam_policies["simulation_power_user"]
#     },

#     {
#       name   = "clue.burnetes@interlacelabs"
#       policy = local.target_iam_policies["simulation_power_user"]
#     },
#   ]

#   target_context_listener_log4shell_http_port = 8000
#   target_context_listener_portforward_ports = flatten([
#     for attacker in local.attacker.port_forward : [
#       {
#         src_port    = 1389
#         dst_ip      = local.attacker.port_forward[0].private_ip
#         dst_port    = 1389
#         description = "log4shell target port forward"
#       },
#       {
#         src_port    = 8080
#         dst_ip      = local.attacker.port_forward[0].private_ip
#         dst_port    = 8080
#         description = "log4shell target port forward"
#       }
#     ]
#   ])

#   attacker_context_responder_log4shell_ldap_port     = 1389
#   attacker_context_responder_log4shell_http_port     = 8080
#   attacker_context_responder_reverseshell_port       = 4444
#   attacker_context_responder_http_port               = 8444
#   attacker_context_responder_portforward_server_port = 8888

#   ssh_port = 22
# }

# #########################
# # ATTACKER ENVIRONMENT
# #
# # deploys attacker environment
# #########################

# module "attacker" {
#   source           = "./modules/environment"
#   environment      = "attacker"
#   region           = var.region
#   aws_profile_name = "attacker"

#   # override enable
#   disable_all = true
#   enable_all  = false

#   # slack
#   enable_slack_alerts = false
#   slack_token         = var.slack_token

#   # jira
#   enable_jira_cloud_alerts = false
#   jira_cloud_url           = var.jira_cloud_url
#   jira_cloud_project_key   = var.jira_cloud_project_key
#   jira_cloud_issue_type    = var.jira_cloud_issue_type
#   jira_cloud_api_token     = var.jira_cloud_api_token
#   jira_cloud_username      = var.jira_cloud_username

#   # eks cluster
#   cluster_name = var.attacker_cluster_name

#   # aws core environment
#   enable_ec2     = false
#   enable_eks     = false
#   enable_eks_app = false
#   enable_eks_psp = false

#   public_network     = "172.18.0.0/16"
#   public_subnet      = "172.18.0.0/24"
#   private_network    = "172.19.0.0/16"
#   private_subnet     = "172.19.100.0/24"
#   private_nat_subnet = "172.19.10.0/24"

#   # aws ssm document setup - provides optional install capability
#   enable_inspector     = false
#   enable_deploy_git    = false
#   enable_deploy_docker = true

#   # ec2 instance definitions
#   instances = local.attacker_instances
#   public_ingress_rules = [
#     {
#       from_port   = local.ssh_port
#       to_port     = local.ssh_port
#       protocol    = "tcp"
#       cidr_block  = "0.0.0.0/0"
#       description = "allow ssh inbound"
#     },
#   ]
#   private_ingress_rules = [
#     {
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_block  = "0.0.0.0/0"
#       description = "allow ssh inbound"
#     }
#   ]

#   # lacework
#   lacework_proxy_token                  = var.lacework_proxy_token
#   lacework_agent_access_token           = var.lacework_agent_access_token
#   lacework_server_url                   = var.lacework_server_url
#   lacework_account_name                 = var.lacework_account_name
#   enable_lacework_alerts                = false
#   enable_lacework_audit_config          = false
#   enable_lacework_custom_policy         = false
#   enable_lacework_daemonset             = false
#   enable_lacework_daemonset_compliance  = false
#   enable_lacework_agentless             = false
#   enable_lacework_ssm_deployment        = false
#   enable_lacework_admission_controller = false
#   enable_lacework_eks_audit             = false

#   providers = {
#     aws        = aws.attacker
#     lacework   = lacework.attacker
#     kubernetes = kubernetes.attacker
#     helm       = helm.attacker
#   }
# }

# #########################
# # TARGET ENVIRONMENT
# #
# # deploys target environment with lacework components installed
# #########################

# module "target" {
#   source           = "./modules/environment"
#   environment      = "target"
#   region           = var.region
#   aws_profile_name = "target"

#   # override enable
#   disable_all = true
#   enable_all  = false

#   # slack
#   enable_slack_alerts = false
#   slack_token         = var.slack_token

#   # jira
#   enable_jira_cloud_alerts = false
#   jira_cloud_url           = var.jira_cloud_url
#   jira_cloud_project_key   = var.jira_cloud_project_key
#   jira_cloud_issue_type    = var.jira_cloud_issue_type
#   jira_cloud_api_token     = var.jira_cloud_api_token
#   jira_cloud_username      = var.jira_cloud_username

#   # eks cluster
#   cluster_name = var.target_cluster_name

#   # aws core environment
#   enable_ec2     = false
#   enable_eks     = false
#   enable_eks_app = false
#   enable_eks_psp = false

#   public_network     = "172.17.0.0/16"
#   public_subnet      = "172.17.0.0/24"
#   private_network    = "172.16.0.0/16"
#   private_subnet     = "172.16.100.0/24"
#   private_nat_subnet = "172.16.10.0/24"

#   # aws ssm document setup - provides optional install capability
#   enable_inspector     = false
#   enable_deploy_git    = false
#   enable_deploy_docker = false

#   # ec2 instance definitions
#   instances = local.target_instances
#   public_ingress_rules = [
#     {
#       from_port   = local.ssh_port
#       to_port     = local.ssh_port
#       protocol    = "tcp"
#       cidr_block  = "0.0.0.0/0"
#       description = "allow ssh inbound"
#     },
#   ]
#   private_ingress_rules = [
#     {
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_block  = "0.0.0.0/0"
#       description = "allow ssh inbound"
#     }
#   ]

#   # kubernetes admission controller
#   lacework_proxy_token = var.lacework_proxy_token

#   # lacework
#   lacework_agent_access_token           = var.lacework_agent_access_token
#   lacework_server_url                   = var.lacework_server_url
#   lacework_account_name                 = var.lacework_account_name
#   enable_lacework_alerts                = false
#   enable_lacework_audit_config          = false
#   enable_lacework_custom_policy         = false
#   enable_lacework_daemonset             = false
#   enable_lacework_daemonset_compliance  = false
#   enable_lacework_agentless             = false
#   enable_lacework_ssm_deployment        = false
#   enable_lacework_admission_controller = false
#   enable_lacework_eks_audit             = false

#   providers = {
#     aws        = aws.target
#     lacework   = lacework.target
#     kubernetes = kubernetes.target
#     helm       = helm.target
#   }
# }

# #########################
# # SIMULATION
# #
# # after infrastructure deployment to attacker and
# # target, use the instance details as parameters
# # for attacker and target simulations.
# #########################

# # simulation for target environment
# locals {
#   target_public_sg_ingress = concat(
#     [
#       for instance in local.attacker.log4shell : {
#         from_port   = local.target_context_listener_log4shell_http_port
#         to_port     = local.target_context_listener_log4shell_http_port
#         protocol    = "tcp"
#         cidr_block  = "${instance.public_ip}/32"
#         description = "allow log4shell inbound"
#       }
#     ],
#   )
# }

# resource "aws_security_group_rule" "simulation-target-public-ingress" {
#   count = length(local.target_public_sg_ingress)

#   type              = "ingress"
#   from_port         = local.target_public_sg_ingress[count.index].from_port
#   to_port           = local.target_public_sg_ingress[count.index].to_port
#   protocol          = local.target_public_sg_ingress[count.index].protocol
#   cidr_blocks       = [local.target_public_sg_ingress[count.index].cidr_block]
#   description       = local.target_public_sg_ingress[count.index].description
#   security_group_id = module.target.public_sg.id

#   provider = aws.target
# }

# # brute force some users - this should be assume role at some point
# resource "aws_iam_user" "target_iam_users" {
#   for_each = { for i in local.target_iam_users : i.name => i }
#   name     = each.key

#   provider = aws.target
# }

# resource "aws_iam_user_policy" "target_iam_users_policy" {
#   for_each = { for i in local.target_iam_users : i.name => i }
#   name     = "iam-policy-${each.value.name}"
#   user     = each.key
#   policy   = each.value.policy

#   provider = aws.target

#   depends_on = [
#     aws_iam_user.target_iam_users
#   ]
# }

# resource "aws_iam_access_key" "target_iam_users_access_key" {
#   for_each = { for i in local.target_iam_users : i.name => i }
#   user     = each.key

#   depends_on = [
#     aws_iam_user.target_iam_users
#   ]

#   provider = aws.target
# }

# data "template_file" "compromised_keys" {
#   for_each = { for i in local.target_iam_users : i.name => i }
#   template = <<-EOT
#     AWS_ACCESS_KEY_ID=${aws_iam_access_key.target_iam_users_access_key[each.key].id}
#     AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.target_iam_users_access_key[each.key].secret}
#     AWS_DEFAULT_REGION=${var.region}
#     AWS_DEFAULT_OUTPUT=json
#     EOT
# }

# module "simulation-target" {
#   source           = "./modules/environment"
#   environment      = "simulation-target"
#   region           = var.region
#   aws_profile_name = "target"

#   # set all endpoint target/attacker
#   attacker_context_instance_http                     = local.attacker.http_listener
#   attacker_context_instance_log4shell                = local.attacker.log4shell
#   attacker_context_instance_reverseshell             = local.attacker.reverseshell
#   attacker_context_instance_portforward              = local.attacker.port_forward
#   attacker_context_responder_portforward_server_port = local.attacker_context_responder_portforward_server_port
#   target_context_instance_log4shell                  = local.target.log4shell
#   target_context_instance_reverseshell               = local.target.reverseshell
#   target_context_instance_portforward                = local.target.port_forward

#   # in simulation cluster name is used to exec kube commands
#   # for example: deploy kali instance
#   cluster_name = var.target_cluster_name

#   # simulation basic
#   # -------------------
#   # no attacker infrastructure required. all attacks run
#   # via ssm as root. any instances tagged will have the
#   # enable attacks run, every 30 minutes by default.
#   enable_target_postcompromise_drop_malware_eicar     = false
#   enable_target_postcompromise_callhome_malware_eicar = false
#   enable_target_postcompromise_enumerate_host         = false
#   enable_target_postcompromise_callhome_oast_host     = false
#   enable_target_postcompromise_kubernetes_app_kali    = false
#   enable_target_postcompromise_docker_cpuminer        = false

#   # simulation advanced
#   # -------------------
#   # attacker endpoint required. these attacks required
#   # two stages. infra build then attack to ensure endpoint
#   # address are available

#   # attack surface host general
#   enable_target_attacksurface_secrets_ssh = true

#   # attack surface kubernetes
#   enable_target_attacksurface_kubernetes_voteapp           = false
#   enable_target_attacksurface_kubernetes_log4shell         = false
#   enable_target_attacksurface_kubernetes_privileged_pod    = false
#   enable_target_attacksurface_kubernetes_root_mount_fs_pod = false

#   # attack surface host log4shell
#   enable_target_attacksurface_docker_log4shell   = false
#   target_context_listener_log4shell_http_port    = local.target_context_listener_log4shell_http_port
#   attacker_context_responder_log4shell_ldap_port = local.attacker_context_responder_log4shell_ldap_port
#   attacker_context_responder_log4shell_http_port = local.attacker_context_responder_log4shell_http_port

#   # call home reverseshell
#   enable_target_postcompromise_callhome_reverseshell = false
#   attacker_context_responder_reverseshell_port       = local.attacker_context_responder_reverseshell_port

#   # call home codecov attack
#   enable_target_postcompromise_callhome_codecov = false
#   attacker_context_responder_http_port          = local.attacker_context_responder_http_port

#   # compromised credentials
#   target_context_credentials_compromised_aws = data.template_file.compromised_keys

#   providers = {
#     aws        = aws.target
#     lacework   = lacework.target
#     kubernetes = kubernetes.target
#     helm       = helm.target
#   }

#   # port forward - setup forwarder in target environment
#   enable_target_postcompromise_port_forward = false
#   target_context_listener_portforward_ports = local.target_context_listener_portforward_ports
# }

# resource "null_resource" "eksips-local-source" {
#   provisioner "local-exec" {
#     command = "echo '${jsonencode(local.target.eks_public_ips)}' > /tmp/local-eksips-source.txt"
#   }
# }

# data "local_file" "eksips-source" {
#   filename   = "/tmp/local-eksips-source.txt"
#   depends_on = [null_resource.eksips-local-source]
# }

# # simulation for attacker environment
# resource "aws_security_group_rule" "simulation-attacker-public-ingress" {
#   for_each = {
#     for rule in concat(
#       # allow all ephemeral inbound from eks nodes
#       [
#         for ip in jsondecode(data.local_file.eksips-source.content) : {
#           from_port   = "1024"
#           to_port     = "65534"
#           protocol    = "tcp"
#           cidr_block  = "${ip}/32"
#           description = "allow eks node inbound"
#         }
#       ],
#       [
#         for instance in local.target.log4shell : {
#           from_port   = local.attacker_context_responder_log4shell_ldap_port
#           to_port     = local.attacker_context_responder_log4shell_ldap_port
#           protocol    = "tcp"
#           cidr_block  = "${instance.public_ip}/32"
#           description = "allow log4shell ldap inbound"
#         }
#       ],
#       [
#         for instance in local.target.log4shell : {
#           from_port   = local.attacker_context_responder_log4shell_http_port
#           to_port     = local.attacker_context_responder_log4shell_http_port
#           protocol    = "tcp"
#           cidr_block  = "${instance.public_ip}/32"
#           description = "allow log4shell http inbound"
#         }
#       ],
#       [
#         for instance in local.target.reverseshell : {
#           from_port   = local.attacker_context_responder_reverseshell_port
#           to_port     = local.attacker_context_responder_reverseshell_port
#           protocol    = "tcp"
#           cidr_block  = "${instance.public_ip}/32"
#           description = "allow reverseshell inbound"
#         }
#       ],
#       [
#         for instance in local.target.codecov : {
#           from_port   = local.attacker_context_responder_http_port
#           to_port     = local.attacker_context_responder_http_port
#           protocol    = "tcp"
#           cidr_block  = "${instance.public_ip}/32"
#           description = "allow codecov http inbound"
#         }
#       ],
#       [
#         for instance in local.target.port_forward : {
#           from_port   = local.attacker_context_responder_portforward_server_port
#           to_port     = local.attacker_context_responder_portforward_server_port
#           protocol    = "tcp"
#           cidr_block  = "${instance.public_ip}/32"
#           description = "allow port forward server inbound"
#         }
#       ],
#     ) : "${rule.cidr_block}:${rule.from_port}:${rule.to_port}" => rule
#   }

#   type              = "ingress"
#   from_port         = each.value.from_port
#   to_port           = each.value.to_port
#   protocol          = each.value.protocol
#   cidr_blocks       = [each.value.cidr_block]
#   description       = each.value.description
#   security_group_id = try(module.attacker.public_sg.id, "")

#   provider = aws.attacker

#   depends_on = [
#     module.target,
#     module.attacker
#   ]
# }

# module "simulation-attacker" {
#   source           = "./modules/environment"
#   environment      = "simulation-attacker"
#   region           = var.region
#   aws_profile_name = "attacker"

#   # set all endpoint target/attacker
#   attacker_context_instance_http         = local.attacker.http_listener
#   attacker_context_instance_log4shell    = local.attacker.log4shell
#   attacker_context_instance_reverseshell = local.attacker.reverseshell
#   attacker_context_instance_portforward  = local.attacker.port_forward
#   target_context_instance_log4shell      = local.target.log4shell
#   target_context_instance_reverseshell   = local.target.reverseshell
#   target_context_instance_portforward    = local.target.port_forward

#   # simulation advanced
#   # -------------------
#   # attacker endpoint required. these attacks required
#   # two stages. infra build then attack to ensure endpoint
#   # address are available

#   # log4shell
#   enable_attacker_compromise_docker_log4shell    = false
#   target_context_listener_log4shell_http_port    = local.target_context_listener_log4shell_http_port
#   attacker_context_responder_log4shell_ldap_port = local.attacker_context_responder_log4shell_ldap_port
#   attacker_context_responder_log4shell_http_port = local.attacker_context_responder_log4shell_http_port
#   attacker_context_payload_log4shell             = <<-EOT
#                                       touch /tmp/log4shell_pwned
#                                       EOT
#   # reverseshell
#   enable_attacker_responder_reverseshell       = false
#   attacker_context_responder_reverseshell_port = local.attacker_context_responder_reverseshell_port
#   attacker_context_payload_reverseshell        = <<-EOT
#                                   touch /tmp/reverseshell_pwned
#                                   EOT

#   # codecov
#   enable_attacker_responder_http       = false
#   attacker_context_responder_http_port = local.attacker_context_responder_http_port

#   # compromised credentials
#   enable_attacker_compromise_compromised_credentials = true
#   target_context_credentials_compromised_aws         = data.template_file.compromised_keys
#   attacker_context_config_protonvpn_user             = var.attacker_context_config_protonvpn_user
#   attacker_context_config_protonvpn_password         = var.attacker_context_config_protonvpn_password
#   attacker_context_config_protonvpn_tier             = var.attacker_context_config_protonvpn_tier
#   attacker_context_config_protonvpn_server           = var.attacker_context_config_protonvpn_server
#   attacker_context_config_protonvpn_protocol         = var.attacker_context_config_protonvpn_protocol
#   attacker_context_config_cryptomining_cloud_wallet  = var.attacker_context_config_cryptomining_cloud_wallet
#   attacker_context_config_cryptomining_host_user     = var.attacker_context_config_cryptomining_host_user

#   providers = {
#     aws        = aws.attacker
#     lacework   = lacework.attacker
#     kubernetes = kubernetes.attacker
#     helm       = helm.attacker
#   }

#   # port forward
#   enable_attacker_responder_port_forward             = false
#   attacker_context_responder_portforward_server_port = local.attacker_context_responder_portforward_server_port
# }