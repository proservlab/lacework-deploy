############################
# Context
############################

variable "config" {
  type = object({
    context = object({
      aws = object({
        iam = object({
          enabled                       = bool
          user_policies = map(string)
          users = list(object({
            name                        = string
            policy                      = string
          }))
        })
        ssm = object({
          docker = object({
            log4j = object({
              enabled                   = bool
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
          log4j = object({
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
      aws = {
        iam = {
          enabled                       = false
          user_policies                 = null
          users                         = null
        }
        ssm = {
          docker = {
            log4j = {
              enabled                   = false
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
          log4j = {
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
            service_port                = 8080
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