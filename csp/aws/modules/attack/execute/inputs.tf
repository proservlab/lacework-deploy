############################
# Context
############################

variable "config" {
  type = object({
    context = object({
      surface = object({
        host = object({
          log4j = object({
            enabled = bool
          })
        })
        kubernetes = object({
          log4j = object({
            enabled = bool
          })
          voteapp = object({
            enabled = bool
          })
          privileged_pod = object({
            enabled = bool
          })
          root_mount_fs_pod = object({
            enabled = bool
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
          root_mount_fs_pod = {
            enabled = false
          }
        }
      }
    }
  }
}

variable "infrastructure" {
  type = object({
    context = object({
      global = object({
          environment               = string
          trust_security_group      = bool
          disable_all               = string
          enable_all                = string
      })
      aws = object({
          region                    = string
          profile_name              = string
          iam                       = any
          ec2                       = any
          eks                       = any
      })
    })
  })
}