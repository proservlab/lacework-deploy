############################
# Context
############################

variable "config" {
  type = object({
    context = object({
      global = object({
        environment               = string
        trust_security_group      = bool
        disable_all               = bool
        enable_all                = bool
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
          private_network       = string
          private_subnet        = string
          private_nat_subnet    = string
          public_ingress_rules  = list(any)
          public_egress_rules   = list(any)
          private_ingress_rules = list(any)
          private_egress_rules  = list(any)
        })
        eks = object({
          enabled               = bool
          cluster_name          = string
        })
        inspector = object({
          enabled               = bool
        })
        ssm = object({
          enabled               = bool
          deploy_git            = bool
          deploy_docker         = bool
          deploy_inspector_agent = bool
          deploy_lacework_agent = bool
          deploy_lacework_syscall_config = bool
        })
      })
      
      lacework = object({
        server_url              = string
        account_name            = string
        audit_config            = object({
          enabled               = bool
        })
        custom_policy = object({
          enabled               = bool
        })
        
        agent = object({
          enabled               = bool
          token                 = string
          host = object({
            ssm = object({
              enabled         = bool
            })
          })
          kubernetes = object({
            proxy_scanner = object({
              token           = string
              enabled         = bool
            })               
            daemonset = object({
              enabled         = bool
              syscall_config  = string
            })
            compliance = object({
              enabled         = bool
            })
            eks_audit_logs = object({
              enabled         = bool
            })
            admission_controller = object({
              enabled         = bool
            })
          })
        })
        agentless = object({
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
    })
  })

  default = {
    context = {
      global = {
        environment               = "infra"
        trust_security_group      = false
        disable_all               = false
        enable_all                = false
      }
      aws = {
        region                    = "us-east-1"
        profile_name              = "infra"
        iam = {
          enabled                 = false
          policies                = null
          users                   = null
        }
        ec2 = {
          enabled               = false
          instances             = []
          public_network        = "172.17.0.0/16"
          public_subnet         = "172.17.0.0/24"
          private_network       = "172.16.0.0/16"
          private_subnet        = "172.16.100.0/24"
          private_nat_subnet    = "172.16.10.0/24"
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
        }
        eks = {
          enabled               = false
          cluster_name          = "infra-cluster"
        }
        inspector = {
          enabled               = false
        }
        ssm = {
          enabled               = false
          deploy_git            = false
          deploy_docker         = false
          deploy_inspector_agent = false
          deploy_lacework_agent = false
          deploy_lacework_syscall_config = false
        }
      }
      lacework = {
        server_url              = null
        account_name            = null
        audit_config            = {
          enabled               = false
        }
        custom_policy = {
          enabled               = false
        }
        agent = {
          enabled               = false
          token                 = null
          host = {
            ssm = {
              enabled           = false
            }
          }
          kubernetes = {
            enabled             = false
            proxy_scanner = {
              token           = null
              enabled         = false
            }             
            daemonset = {
              enabled         = false
              syscall_config  = null
            }
            compliance = {
              enabled         = false
            }
            eks_audit_logs = {
              enabled         = false
            }
            admission_controller = {
              enabled         = false
            }
          }
        }
        agentless = {
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
    }
  }
}