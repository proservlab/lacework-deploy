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
        disable_all               = bool
        enable_all                = bool
      })
      azure = object({
        compute = object({
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
          add_app_trusted_ingress = object({
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
        runbook = object({
          vulnerable = object({
            docker = object({
              log4shellapp = object({
                enabled                   = bool
                listen_port               = number
              })
            })
            log4j_app = object({
              enabled                   = bool
              listen_port               = number
            })
            npm_app = object({
              enabled                   = bool
              listen_port               = number
            })
            python3_twisted_app = object({
              enabled                   = bool
              listen_port               = number
            })
          })
          ssh_keys = object({ 
            enabled                     = bool
            ssh_private_key_path        = string
            ssh_public_key_path         = string
            ssh_authorized_keys_path    = string
          })
          ssh_user = object({ 
            enabled                     = bool
            username                    = string
            password                    = string
          })
          azure_credentials = object({ 
            enabled                     = bool
            compromised_keys_user       = string
          })
        })
      })
      gcp = object({
        iam = object({
          enabled                       = bool
          user_policies_path = string
          users_path = string
        })
        gce = object({
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
          add_app_trusted_ingress = object({
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
        osconfig = object({
          vulnerable = object({
            docker = object({
              log4shellapp = object({
                enabled                   = bool
                listen_port               = number
              })
            })
            log4j_app = object({
              enabled                   = bool
              listen_port               = number
            })
            npm_app = object({
              enabled                   = bool
              listen_port               = number
            })
            python3_twisted_app = object({
              enabled                   = bool
              listen_port               = number
            })
          })
          ssh_keys = object({ 
            enabled                     = bool
            ssh_private_key_path        = string
            ssh_public_key_path         = string
            ssh_authorized_keys_path    = string
          })
          ssh_user = object({ 
            enabled                     = bool
            username                    = string
            password                    = string
          })
          gcp_credentials = object({ 
            enabled                     = bool
            compromised_keys_user       = string
          })
        })
      })
      aws = object({
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
          add_app_trusted_ingress = object({
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
        eks = object({
          add_iam_user_readonly_user = object({
            enabled = bool
            iam_user_names =  list(string)
          })
          add_iam_user_admin_user = object({
            enabled = bool
            iam_user_names =  list(string)
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
            log4j_app = object({
              enabled                   = bool
              listen_port               = number
            })
            npm_app = object({
              enabled                   = bool
              listen_port               = number
            })
            python3_twisted_app = object({
              enabled                   = bool
              listen_port               = number
            })
            rds_app = object({
              enabled                   = bool
              listen_port               = number
            })
          })
          ssh_keys = object({ 
            enabled                     = bool
            ssh_private_key_path        = string
            ssh_public_key_path         = string
            ssh_authorized_keys_path    = string
          })
          ssh_user = object({ 
            enabled                     = bool
            username                    = string
            password                    = string
          })
          aws_credentials = object({ 
            enabled                     = bool
            compromised_keys_user       = string
          })
        })
      })
      kubernetes = object({
        aws = object({
          app = object({
            enabled                       = bool
          })
          app-windows = object({
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
              image                       = string
              command                     = list(string)
              args                        = list(string)
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
              service_port                = number
              trust_attacker_source       = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
              image                       = string
              command                     = list(string)
              args                        = list(string)
            })
            root_mount_fs_pod = object({
              enabled                     = bool
            })
          })
        })
        gcp = object({
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
              image                       = string
              command                     = list(string)
              args                        = list(string)
            })
            voteapp = object({
              enabled                     = bool
              vote_service_port           = number
              result_service_port         = number
              trust_attacker_source       = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
            })
            privileged_pod = object({
              enabled                     = bool
              service_port                = number
              trust_attacker_source       = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
              image                       = string
              command                     = list(string)
              args                        = list(string)
            })
            root_mount_fs_pod = object({
              enabled                     = bool
            })
          })
        })
        azure = object({
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
              image                       = string
              command                     = list(string)
              args                        = list(string)
            })
            voteapp = object({
              enabled                     = bool
              vote_service_port           = number
              result_service_port         = number
              trust_attacker_source       = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
            })
            privileged_pod = object({
              enabled                     = bool
              service_port                = number
              trust_attacker_source       = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
              image                       = string
              command                     = list(string)
              args                        = list(string)
            })
            root_mount_fs_pod = object({
              enabled                     = bool
            })
          })
        })
      })
    })
  })

  default = {
    context = {
      global = {
        environment               = "target"
        deployment                = "default"
        disable_all               = false
        enable_all                = false
      }
      azure = {
        compute = {
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
          },
          add_app_trusted_ingress = {
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
        runbook = {
          vulnerable = {
            docker = {
              log4shellapp = {
                enabled                   = false
                listen_port               = 8000
              }
            },
            log4j_app = {
              enabled                   = false
              listen_port               = 8080
            }
            npm_app = {
              enabled                   = false
              listen_port               = 8089
            }
            python3_twisted_app = {
              enabled                   = false
              listen_port               = 8090
            }
          }
          ssh_keys = {
            enabled                     = false
            ssh_private_key_path        = "/home/ubuntu/.ssh/secret_key"
            ssh_public_key_path         = "/home/ubuntu/.ssh/secret_key.pub"
            ssh_authorized_keys_path    = "/home/ubuntu/.ssh/authorized_keys"
          }
          ssh_user = {
            enabled                     = false
            username                    = "lou.caloozer"
            password                    = null
          }
          azure_credentials = {
            enabled                     = false
            compromised_keys_user       = null
          }
        }
      }
      gcp = {
        iam = {
          enabled                       = false
          user_policies_path            = null
          users_path                    = null
        }
        gce = {
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
          },
          add_app_trusted_ingress = {
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
        osconfig = {
          vulnerable = {
            docker = {
              log4shellapp = {
                enabled                   = false
                listen_port               = 8000
              }
            },
            log4j_app = {
              enabled                   = false
              listen_port               = 8080
            }
            npm_app = {
              enabled                   = false
              listen_port               = 8089
            }
            python3_twisted_app = {
              enabled                   = false
              listen_port               = 8090
            }
          }
          ssh_keys = {
            enabled                     = false
            ssh_private_key_path        = "/home/ubuntu/.ssh/secret_key"
            ssh_public_key_path         = "/home/ubuntu/.ssh/secret_key.pub"
            ssh_authorized_keys_path    = "/home/ubuntu/.ssh/authorized_keys"
          },
          ssh_user = {
            enabled                     = false
            username                    = "lou.caloozer"
            password                    = null
          },
          gcp_credentials = {
            enabled                     = false
            compromised_keys_user       = null
          }
        }
      }
      aws = {
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
          },
          add_app_trusted_ingress = {
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
        eks = {
          add_iam_user_readonly_user = {
            enabled = false
            iam_user_names =  []
          }
          add_iam_user_admin_user = {
            enabled = false
            iam_user_names =  []
          }
        }
        ssm = {
          vulnerable = {
            docker = {
              log4shellapp = {
                enabled                   = false
                listen_port               = 8000
              }
            },
            log4j_app = {
              enabled                   = false
              listen_port               = 8080
            }
            npm_app = {
              enabled                   = false
              listen_port               = 8089
            }
            python3_twisted_app = {
              enabled                   = false
              listen_port               = 8090
            }
            rds_app = {
              enabled                   = false
              listen_port               = 8091
            }
          }
          ssh_keys = {
            enabled                     = false
            ssh_private_key_path        = "/home/ubuntu/.ssh/secret_key"
            ssh_public_key_path         = "/home/ubuntu/.ssh/secret_key.pub"
            ssh_authorized_keys_path    = "/home/ubuntu/.ssh/authorized_keys"
          },
          ssh_user = {
            enabled                     = false
            username                    = "lou.caloozer"
            password                    = null
          },
          aws_credentials = { 
            enabled                     = false
            compromised_keys_user       = null
          }
        }
      }
      kubernetes = {
        gcp = {
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
              image                       = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
              command                     = ["java"]
              args                        = ["-jar", "/app/spring-boot-application.jar"]
            }
            voteapp = {
              enabled                     = false
              vote_service_port           = 8001
              result_service_port         = 8002
              trust_attacker_source       = true
              trust_workstation_source    = true
              additional_trusted_sources = []
            }
            privileged_pod = {
              enabled                     = false
              service_port                = 8003
              trust_attacker_source       = true
              trust_workstation_source    = true
              additional_trusted_sources  = []
              image                       = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
              command                     = ["java"]
              args                        = ["-jar", "/app/spring-boot-application.jar"]
            }
            root_mount_fs_pod = {
              enabled = false
            }
          }
        }
        aws = {
          app = {
            enabled                       = false
          }
          app-windows = {
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
              image                       = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
              command                     = ["java"]
              args                        = ["-jar", "/app/spring-boot-application.jar"]
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
              enabled                     = false
              service_port                = 8003
              trust_attacker_source       = true
              trust_workstation_source    = true
              additional_trusted_sources  = []
              image                       = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
              command                     = ["java"]
              args                        = ["-jar", "/app/spring-boot-application.jar"]
            }
            root_mount_fs_pod = {
              enabled = false
            }
          }
        }
        azure = {
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
              image                       = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
              command                     = ["java"]
              args                        = ["-jar", "/app/spring-boot-application.jar"]
            }
            voteapp = {
              enabled                     = false
              vote_service_port           = 8001
              result_service_port         = 8002
              trust_attacker_source       = true
              trust_workstation_source    = true
              additional_trusted_sources = []
            }
            privileged_pod = {
              enabled                     = false
              service_port                = 8003
              trust_attacker_source       = true
              trust_workstation_source    = true
              additional_trusted_sources  = []
              image                       = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
              command                     = ["java"]
              args                        = ["-jar", "/app/spring-boot-application.jar"]
            }
            root_mount_fs_pod = {
              enabled = false
            }
          }
        }
      }
    }
  }

  validation {
    condition     = contains(["target","attacker"],var.config.context.global.environment)
    error_message = "Environment must be either 'target' or 'attacker'."
  }
}