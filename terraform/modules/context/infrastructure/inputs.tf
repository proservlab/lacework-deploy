##################################################
# Context
##################################################

variable "parent" {
  type = list(string)
  default = []
} 

variable "config" {
  type = object({
    context = object({
      global = object({
        environment               = string
        deployment                = string
        trust_security_group      = bool
        disable_all               = bool
        enable_all                = bool
      })
      azure = object({
        region                  = string
        subscription            = string
        tenant                  = string
        compute = object({
          enabled               = bool
          instances             = list(any)
          public_network        = string
          public_subnet         = string
          public_app_network    = string
          public_app_subnet     = string
          private_network       = string
          private_subnet        = string
          private_nat_subnet    = string
          private_app_network   = string
          private_app_subnet    = string
          private_app_nat_subnet = string
          public_ingress_rules  = list(any)
          public_egress_rules   = list(any)
          public_app_ingress_rules  = list(any)
          public_app_egress_rules   = list(any)
          private_ingress_rules = list(any)
          private_egress_rules  = list(any)
          private_app_ingress_rules = list(any)
          private_app_egress_rules  = list(any)
        })
        aks = object({
          enabled               = bool
          cluster_name          = string
        })
        azuresql = object({
          enabled               = bool
          instance_type         = string
          sku_name              = string
          server_name           = string
          db_name               = string
          public_network_access_enabled = bool
          service_principal_name = string
        })
        azurestorage = object({
          enabled               = bool
          account_tier          = string
          account_replication_type = string
          public_network_access_enabled = bool
        })
        runbook = object({
          enabled               = bool
          deploy_git            = object({
            enabled             = bool
          })
          deploy_docker         = object({
            enabled             = bool
            docker_users        = list(string)
          })
          deploy_lacework_agent = object({
            enabled             = bool
          })
          deploy_lacework_syscall_config = object({
            enabled             = bool
          })
          deploy_lacework_code_aware_agent = object({
            enabled             = bool
          })
          deploy_azure_cli        = object({
            enabled             = bool
          })
          deploy_lacework_cli   = object({
            enabled             = bool
          })
          deploy_kubectl_cli    = object({
            enabled             = bool
          })
          deploy_protonvpn_docker = object({
            enabled             = bool
          })
        })
      })
      gcp = object({
        region                    = string
        project_id                = string
        data_access_audit         = object({
          enabled                = bool
        })
        gce = object({
          enabled               = bool
          instances             = list(any)
          public_network        = string
          public_subnet         = string
          public_app_network    = string
          public_app_subnet     = string
          private_network       = string
          private_subnet        = string
          private_nat_subnet    = string
          private_app_network   = string
          private_app_subnet    = string
          private_app_nat_subnet = string
          public_ingress_rules  = list(any)
          public_egress_rules   = list(any)
          public_app_ingress_rules  = list(any)
          public_app_egress_rules   = list(any)
          private_ingress_rules = list(any)
          private_egress_rules  = list(any)
          private_app_ingress_rules = list(any)
          private_app_egress_rules  = list(any)
        })
        cloudsql = object({
          enabled                       = bool
          user_role_name                = string
          instance_type                 = string
          enable_public_ip              = bool
          require_ssl                   = bool
          authorized_networks           = list(string)
        })
        gke = object({
          enabled               = bool
          cluster_name          = string
        })
        osconfig = object({
          enabled               = bool
          deploy_git            = object({
            enabled             = bool
          })
          deploy_docker         = object({
            enabled             = bool
            docker_users        = list(string)
          })
          deploy_lacework_agent = object({
            enabled             = bool
          })
          deploy_lacework_syscall_config = object({
            enabled             = bool
          })
          deploy_lacework_code_aware_agent = object({
            enabled             = bool
          })
          deploy_gcp_cli        = object({
            enabled             = bool
          })
          deploy_lacework_cli   = object({
            enabled             = bool
          })
          deploy_kubectl_cli    = object({
            enabled             = bool
          })
          deploy_protonvpn_docker = object({
            enabled             = bool
          })
        })
      })
      aws = object({
        region                    = string
        profile_name              = string
        iam = object({
          enabled                 = bool
          policies                = any
          users                   = any
        })
        ec2 = object({
          enabled               = bool
          instances             = list(any)
          public_network        = string
          public_subnet         = string
          public_app_network    = string
          public_app_subnet     = string
          private_network       = string
          private_subnet        = string
          private_nat_subnet    = string
          private_app_network   = string
          private_app_subnet    = string
          private_app_nat_subnet = string
          public_ingress_rules  = list(any)
          public_egress_rules   = list(any)
          public_app_ingress_rules  = list(any)
          public_app_egress_rules   = list(any)
          private_ingress_rules = list(any)
          private_egress_rules  = list(any)
          private_app_ingress_rules = list(any)
          private_app_egress_rules  = list(any)
        })
        eks = object({
          enabled               = bool
          cluster_name          = string
          deploy_calico         = bool
        })
        eks-windows = object({
          enabled               = bool
          cluster_name          = string
        })
        rds = object({
          enabled                       = bool
          user_role_name                = string
          instance_type                 = string
          instance_name                 = string
        })
        inspector = object({
          enabled               = bool
        })
        ssm = object({
          enabled               = bool
          deploy_git            = object({
            enabled             = bool
          })
          deploy_docker         = object({
            enabled             = bool
            docker_users        = list(string)
          })
          deploy_inspector_agent = object({
            enabled             = bool
          })
          deploy_lacework_agent = object({
            enabled             = bool
          })
          deploy_lacework_syscall_config = object({
            enabled             = bool
          })
          deploy_lacework_code_aware_agent = object({
            enabled             = bool
          })
          deploy_aws_cli        = object({
            enabled             = bool
          })
          deploy_lacework_cli   = object({
            enabled             = bool
          })
          deploy_kubectl_cli    = object({
            enabled             = bool
          })
          deploy_protonvpn_docker = object({
            enabled             = bool
          })
        })
      })
      
      lacework = object({
        server_url              = string
        account_name            = string
        profile_name            = string
        aws_audit_config        = object({
          enabled               = bool
          create_lacework_integration = bool
          consolidated_trail = bool
          is_organization_trail = bool
          org_account_mappings = list(object({
              default_lacework_account = string
              mapping = list(object({
                lacework_account = string
                aws_accounts     = list(string)
              }))
            }))
          use_existing_kms_key = bool
          use_existing_iam_role = bool
          use_existing_iam_role_policy = bool
          iam_role_name = string
          iam_role_arn = string
          iam_role_external_id = string
          permission_boundary_arn = string
          external_id_length = number
          prefix = string
          enable_log_file_validation = bool
          bucket_name = string
          bucket_arn = string
          bucket_encryption_enabled = bool
          bucket_logs_enabled = bool
          bucket_enable_mfa_delete = bool
          bucket_versioning_enabled = bool
          bucket_force_destroy = bool
          bucket_sse_algorithm = string
          bucket_sse_key_arn = string
          log_bucket_name = string
          access_log_prefix = string
          s3_notification_log_prefix = string
          s3_notification_type = string
          sns_topic_arn = string
          sns_topic_name = string
          sns_topic_encryption_key_arn = string
          sns_topic_encryption_enabled = bool
          sqs_queue_name = string
          sqs_encryption_enabled = bool
          sqs_encryption_key_arn = string
          use_s3_bucket_notification = bool
          use_existing_cloudtrail = bool
          use_existing_access_log_bucket = bool
          use_existing_sns_topic = bool
          cloudtrail_name = string
          cross_account_policy_name = string
          sqs_queues = list(string)
          lacework_integration_name = string
          lacework_aws_account_id = string
          wait_time = string
          tags = map(string)
          kms_key_rotation = bool
          kms_key_deletion_days = number
          kms_key_multi_region = bool
          enable_cloudtrail_s3_management_events = bool
        })
        gcp_audit_config        = object({
          project_id            = string
          enabled               = bool
          use_pub_sub           = bool
          org_integration       = bool
        })
        azure_audit_config      = object({
          enabled                       = bool
          enable_entra_id_activity_logs = bool
        })
        custom_policy = object({
          enabled               = bool
        })
        aws_ecr                 = object({
          enabled               = bool
        })
        
        agent = object({
          enabled               = bool
          token                 = string
          build_hash            = string
          kubernetes = object({
            proxy_scanner = object({
              token           = string
              enabled         = bool
            })               
            daemonset = object({
              enabled               = bool
              syscall_config_path   = string
            })
            daemonset-windows = object({
              enabled               = bool
              syscall_config_path   = string
            })
            compliance = object({
              enabled         = bool
            })
            eks_audit_logs = object({
              enabled         = bool
            })
            gke_audit_logs = object({
              enabled         = bool
            })
            admission_controller = object({
              enabled         = bool
            })
          })
        })
        aws_agentless = object({
          enabled               = bool
          use_existing_vpc      = bool
          vpc_id                = string
          vpc_cidr_block        = string
        })
        gcp_agentless = object({
          enabled               = bool
          org_integration       = bool
        })
        azure_agentless = object({
          enabled               = bool
        })
        alerts = object({
          enabled               = bool
          slack = object({
            enabled             = bool
            api_token           = string
          })
          jira = object({
            enabled             = bool
            cloud_url           = string
            cloud_username      = string
            cloud_api_token     = string
            cloud_project_key   = string
            cloud_issue_type    = string
          })
        })
      })
      dynu_dns = object({
        enabled                 = bool
        api_key                 = string
        dns_domain              = string
        domain_id               = string
      })
    })
  })

  default = {
    context = {
      global = {
        environment               = "target"
        deployment                = "default"
        trust_security_group      = true
        disable_all               = false
        enable_all                = false
      }
      azure = {
        region                  = "West US 2"
        subscription            = null
        tenant                  = null
        compute = {
          enabled               = false
          instances             = []
          public_network        = "172.18.0.0/16"
          public_subnet         = "172.18.0.0/24"
          public_app_network    = "172.19.0.0/16"
          public_app_subnet     = "172.19.0.0/24"
          private_network       = "172.16.0.0/16"
          private_subnet        = "172.16.100.0/24"
          private_nat_subnet    = "172.16.10.0/24"
          private_app_network       = "172.17.0.0/16"
          private_app_subnet        = "172.17.100.0/24"
          private_app_nat_subnet    = "172.17.10.0/24"
          public_ingress_rules  = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    },
                                  ]
          public_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
          public_app_ingress_rules  = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    },
                                  ]
          public_app_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
          private_ingress_rules = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    }
                                  ]
          private_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
          private_app_ingress_rules = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    }
                                  ]
          private_app_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
        }
        aks = {
          enabled               = false
          cluster_name          = "infra-cluster"
        }
        azurestorage = {
          enabled               = false
          account_tier          = "Standard"
          account_replication_type = "GRS"
          public_network_access_enabled = false
        }
        azuresql = {
          enabled               = false
          instance_type         = "mysql"
          sku_name              = "GP_Standard_D2ds_v4"
          server_name           = "azuresql"
          db_name               = "db"
          public_network_access_enabled = false
          service_principal_name = null
        }
        runbook = {
          enabled               = false
          deploy_git            = {
            enabled             = false
          }
          deploy_docker         = {
            enabled             = false
            docker_users        = []
          }
          deploy_lacework_agent = {
            enabled             = false
          }
          deploy_lacework_syscall_config = {
            enabled             = false
          }
          deploy_lacework_code_aware_agent = {
            enabled             = false
          }
          deploy_azure_cli        = {
            enabled             = false
          }
          deploy_lacework_cli   = {
            enabled             = false
          }
          deploy_kubectl_cli    = {
            enabled             = false
          }
          deploy_protonvpn_docker = {
            enabled             = false
          }
        }
      }
      gcp = {
        region                    = "us-central1"
        project_id                = null
        data_access_audit = {
          enabled                = false
        }
        gce = {
          enabled               = false
          instances             = []
          public_network        = "172.18.0.0/16"
          public_subnet         = "172.18.0.0/24"
          public_app_network    = "172.19.0.0/16"
          public_app_subnet     = "172.19.0.0/24"
          private_network       = "172.16.0.0/16"
          private_subnet        = "172.16.100.0/24"
          private_nat_subnet    = "172.16.10.0/24"
          private_app_network       = "172.17.0.0/16"
          private_app_subnet        = "172.17.100.0/24"
          private_app_nat_subnet    = "172.17.10.0/24"
          public_ingress_rules  = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    },
                                  ]
          public_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
          public_app_ingress_rules  = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    },
                                  ]
          public_app_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
          private_ingress_rules = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    }
                                  ]
          private_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
          private_app_ingress_rules = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    }
                                  ]
          private_app_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
        }
        cloudsql = {
          enabled                       = false
          user_role_name                = "cloudsql_user_access_role"
          instance_type                 = "db-f1-micro"
          enable_public_ip              = false
          require_ssl                   = false
          authorized_networks           = []
        }
        gke = {
          enabled               = false
          cluster_name          = "infra-cluster"
        }
        osconfig = {
          enabled               = false
          deploy_git            = {
            enabled             = false
          }
          deploy_docker         = {
            enabled             = false
            docker_users        = []
          }
          deploy_lacework_agent = {
            enabled             = false
          }
          deploy_lacework_syscall_config = {
            enabled             = false
          }
          deploy_lacework_code_aware_agent = {
            enabled             = false
          }
          deploy_gcp_cli        = {
            enabled             = false
          }
          deploy_lacework_cli   = {
            enabled             = false
          }
          deploy_kubectl_cli    = {
            enabled             = false
          }
          deploy_protonvpn_docker = {
            enabled             = false
          }
        }
      }
      aws = {
        region                    = "us-east-1"
        profile_name              = null
        iam = {
          enabled                 = false
          policies                = null
          users                   = null
        }
        ec2 = {
          enabled               = false
          instances             = []
          public_network        = "172.18.0.0/16"
          public_subnet         = "172.18.0.0/24"
          public_app_network    = "172.19.0.0/16"
          public_app_subnet     = "172.19.0.0/24"
          private_network       = "172.16.0.0/16"
          private_subnet        = "172.16.100.0/24"
          private_nat_subnet    = "172.16.10.0/24"
          private_app_network       = "172.17.0.0/16"
          private_app_subnet        = "172.17.100.0/24"
          private_app_nat_subnet    = "172.17.10.0/24"
          public_ingress_rules  = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    },
                                  ]
          public_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
          public_app_ingress_rules  = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    },
                                  ]
          public_app_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
          private_ingress_rules = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    }
                                  ]
          private_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
          private_app_ingress_rules = [
                                    {
                                      from_port   = 22
                                      to_port     = 22
                                      protocol    = "tcp"
                                      cidr_block  = "0.0.0.0/0"
                                      description = "allow ssh inbound"
                                    }
                                  ]
          private_app_egress_rules = [ 
                                  {
                                    from_port = 0
                                    to_port = 0
                                    protocol = "-1"
                                    cidr_block = "0.0.0.0/0"
                                    description = "allow all outbound"
                                  }
                                ]
        }
        eks = {
          enabled               = false
          cluster_name          = "infra-cluster"
          deploy_calico         = false
        }

        eks-windows = {
          enabled               = false
          cluster_name          = "infra-windows-cluster"
        }
        rds = {
          enabled                       = false
          user_role_name                = "rds_user_access_role"
          instance_type                 = "db.t3.small"
          instance_name                 = "ec2rds"
        }
        inspector = {
          enabled               = false
        }
        ssm = {
          enabled               = false
          deploy_git            = {
            enabled             = false
          }
          deploy_docker         = {
            enabled             = false
            docker_users        = []
          }
          deploy_inspector_agent = {
            enabled             = false
          }
          deploy_lacework_agent = {
            enabled             = false
          }
          deploy_lacework_syscall_config = {
            enabled             = false
          }
          deploy_lacework_code_aware_agent = {
            enabled             = false
          }
          deploy_aws_cli        = {
            enabled             = false
          }
          deploy_lacework_cli   = {
            enabled             = false
          }
          deploy_kubectl_cli    = {
            enabled             = false
          }
          deploy_protonvpn_docker = {
            enabled             = false
          }
        }
      }
      lacework = {
        server_url              = null
        account_name            = null
        profile_name            = null
        aws_audit_config            = {
          enabled               = false,
          create_lacework_integration = true,
          consolidated_trail = false,
          is_organization_trail = false
          org_account_mappings = []
          use_existing_kms_key = false
          use_existing_iam_role = false
          use_existing_iam_role_policy = false
          iam_role_name = ""
          iam_role_arn = ""
          iam_role_external_id = ""
          permission_boundary_arn = null
          external_id_length = 16
          prefix = "lacework-ct"
          enable_log_file_validation = true
          bucket_name = ""
          bucket_arn = ""
          bucket_encryption_enabled = true
          bucket_logs_enabled = true
          bucket_enable_mfa_delete = false
          bucket_versioning_enabled = true
          bucket_force_destroy = true
          bucket_sse_algorithm = "aws:kms"
          bucket_sse_key_arn = ""
          log_bucket_name = ""
          access_log_prefix = "log/"
          s3_notification_log_prefix = "AWSLogs/"
          s3_notification_type = "SQS"
          sns_topic_arn = ""
          sns_topic_name = ""
          sns_topic_encryption_key_arn = ""
          sns_topic_encryption_enabled = true
          sqs_queue_name = ""
          sqs_encryption_enabled = true
          sqs_encryption_key_arn = ""
          use_s3_bucket_notification = false
          use_existing_cloudtrail = false
          use_existing_access_log_bucket = false
          use_existing_sns_topic = false
          cloudtrail_name = "lacework-cloudtrail"
          cross_account_policy_name = ""
          sqs_queues = []
          lacework_integration_name = "TF cloudtrail"
          lacework_aws_account_id = "434813966438"
          wait_time = "10s"
          tags = {}
          kms_key_rotation = false
          kms_key_deletion_days = 30
          kms_key_multi_region = true
          enable_cloudtrail_s3_management_events = false
        }
        gcp_audit_config            = {
          project_id            = null
          enabled               = false
          use_pub_sub           = false
          org_integration       = false
        }
        azure_audit_config          = {
          enabled                       = false
          enable_entra_id_activity_logs = false
        }
        custom_policy = {
          enabled               = false
        }
        aws_ecr                     = {
          enabled               = false
        }
        agent = {
          enabled               = false
          token                 = null
          build_hash            = null
          kubernetes = {
            enabled             = false
            proxy_scanner = {
              token           = null
              enabled         = false
            }             
            daemonset = {
              enabled              = false
              syscall_config_path  = null
            }
            daemonset-windows = {
              enabled              = false
              syscall_config_path  = null
            }
            compliance = {
              enabled         = false
            }
            eks_audit_logs = {
              enabled         = false
            }
            gke_audit_logs = {
              enabled         = false
            }
            admission_controller = {
              enabled         = false
            }
          }
        }
        aws_agentless = {
          enabled               = false
          use_existing_vpc      = false
          vpc_id                = null
          vpc_cidr_block        = null
        }
        gcp_agentless = {
          enabled               = false
          org_integration       = false
        }
        azure_agentless = {
          enabled               = false
        }
        alerts = {
          enabled               = false
          slack = {
            enabled             = false
            api_token           = null
          }
          jira = {
            enabled             = false
            cloud_url           = null
            cloud_username      = null
            cloud_api_token     = null
            cloud_project_key   = null
            cloud_issue_type    = null
          }
        }
      }
      dynu_dns = {
        enabled                 = false
        api_key                 = null
        dns_domain              = null
        domain_id               = null
      }
    }
  }
  validation {
    condition     = contains(["target","attacker"],var.config.context.global.environment)
    error_message = "Environment must be either 'target' or 'attacker'."
  }
}