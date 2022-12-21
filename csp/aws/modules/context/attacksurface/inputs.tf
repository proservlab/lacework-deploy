############################
# Context
############################

variable "config" {
  type = object({
    context = object({
      surface = object({
        host = object({
          log4j = object({
            enabled                 = bool
          })
        })
        kubernetes = object({
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
      surface = {
        host = {
          log4j = {
            enabled = false
          }
          ssh_keys = {
            enabled = false
          }
        }
        kubernetes = {
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