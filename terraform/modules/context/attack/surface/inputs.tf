############################
# Context
############################ 
variable "config" {
  type = object({
    context = object({
      global = object({
        environment               = string
        deployment                = string
        disable_all               = bool
        enable_all                = bool
      })
      gcp = object({
        region                    = string
        project_id                = string
      })
      aws = object({
        region                    = string
        profile_name              = string
        iam = object({
          enabled                       = bool
          user_policies_path = string
          users_path = string
        })
        ec2 = object({
          add_trusted_ingress = object({
            enabled                     = bool
            trust_workstation           = bool
            trust_attacker_source       = bool
            trust_target_source         = bool
            additional_trusted_sources  = list(string)
            trusted_tcp_ports           = object({
              from_port                 = number
              to_port                   = number
            })
          })
        })
        ssm = object({
          vulnerable = object({
            docker = object({
              log4shellapp = object({
                enabled                   = bool
                listen_port               = number
              })
            })
          })
          ssh_keys = object({ 
            enabled                     = bool
          })
        })
      })
      kubernetes = object({
        app = object({
          enabled                       = bool
        })
        psp = object({
          enabled                       = bool
        })
        vulnerable = object({
          log4shellapp = object({
            enabled                     = bool
            service_port                = number
            trust_attacker_source       = bool
            trust_workstation_source    = bool
            additional_trusted_sources  = list(string)
          })
          voteapp = object({
            enabled                     = bool
            vote_service_port           = number
            result_service_port         = number
            trust_attacker_source       = bool
            trust_workstation_source    = bool
            additional_trusted_sources  = list(string)
          })
          rdsapp = object({
            enabled                     = bool
            service_port                = number
            trust_attacker_source       = bool
            trust_workstation_source    = bool
            additional_trusted_sources  = list(string)
          })
          privileged_pod = object({
            enabled                     = bool
          })
          root_mount_fs_pod = object({
            enabled                     = bool
          })
        })
      })
    })
  })

  default = {
    context = {
      global = {
        environment               = "infra"
        deployment                = "default"
        disable_all               = false
        enable_all                = false
      }
      gcp = {
        region                    = "us-central1"
        project_id                = null
      }
      aws = {
        region                    = "us-east-1"
        profile_name              = "infra"
        iam = {
          enabled                       = false
          user_policies_path            = null
          users_path                    = null
        }
        ec2 = {
          add_trusted_ingress = {
            enabled                     = false
            trust_workstation           = false
            trust_attacker_source       = false
            trust_target_source         = false
            additional_trusted_sources  = []
            trusted_tcp_ports           = {
              from_port = 1024
              to_port = 65535
            }
          }
        }
        ssm = {
          vulnerable = {
            docker = {
              log4shellapp = {
                enabled                   = false
                listen_port               = 8000
              }
            }
          }
          ssh_keys = {
            enabled                     = false
          }
        }
      }
      kubernetes = {
        app = {
          enabled                       = false
        }
        psp = {
          enabled                       = false
        }
        vulnerable = {
          log4shellapp = {
            enabled                     = false
            service_port                = 8000
            trust_attacker_source       = true
            trust_workstation_source    = true
            additional_trusted_sources  = []
          }
          voteapp = {
            enabled                     = false
            vote_service_port           = 8001
            result_service_port         = 8002
            trust_attacker_source       = true
            trust_workstation_source    = true
            additional_trusted_sources = []
          }

          rdsapp = {
            enabled                     = false
            service_port                = 8000
            trust_attacker_source       = true
            trust_workstation_source    = true
            additional_trusted_sources  = []
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
}