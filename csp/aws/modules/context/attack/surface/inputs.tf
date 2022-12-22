############################
# Context
############################

variable "config" {
  type = object({
    context = object({
      aws = object({
        iam = object({
          enabled                  = bool
          user_policies = map(string)
          users = list(object({
            name                    = string
            policy                  = string
          }))
        })
        ssm = object({
          docker = object({
            log4j = object({
              enabled                 = bool
            })
          })
          ssh_keys = object({
            enabled                 = bool
          })
        })
      })
      kubernetes = object({
        app = object({
          enabled                 = bool
        })
        psp = object({
          enabled                 = bool
        })
        vulnerable = object({
          log4j = object({
            enabled                 = bool
          })
          voteapp = object({
            enabled                 = bool
          })
          privileged_pod = object({
            enabled                 = bool
          })
          root_mount_fs_pod = object({
            enabled                 = bool
          })
        })
      })
    })
  })

  default = {
    context = {
      aws = {
        iam = {
          enabled = false
          user_policies = null
          users = null
        }
        ssm = {
          docker = {
            log4j = {
              enabled = false
            }
          }
          ssh_keys = {
            enabled = false
          }
        }
      }
      kubernetes = {
        app = {
          enabled = false
        }
        psp = {
          enabled = false
        }
        vulnerable = {
          log4j = {
            enabled = false
          }
          voteapp = {
            enabled = false
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