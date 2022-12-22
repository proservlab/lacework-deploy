############################
# Context
############################

variable "config" {
  type = object({
    context = object({
      aws = object({
        host = object({
          log4j = object({
            enabled                 = bool
          })
          ssh_keys = object({
            enabled                 = bool
          })
        })
        eks = object({
          app = object({
            enabled                 = bool
          })
          psp = object({
            enabled                 = bool
          })
          log4j = object({
            enabled                 = bool
          })
          voteapp = object({
            enabled                 = bool
          })
          privileged_pod = object({
            enabled                 = bool
          })
          root_mount_fs = object({
            enabled                 = bool
          })
        })
      })
    })
  })

  default = {
    context = {
      aws = {
        host = {
          log4j = {
            enabled = false
          }
          ssh_keys = {
            enabled = false
          }
        }
        eks = {
          app = {
            enabled = false
          }
          psp = {
            enabled = false
          }
          log4j = {
            enabled = false
          }
          voteapp = {
            enabled = false
          }
          privileged_pod = {
            enabled = false
          }
          root_mount_fs = {
            enabled = false
          }
        }
      }
    }
  }
}

variable "infrastructure" {
  type = object({
    config = any
    deployed_state = any
  })
}