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
            trust_workstation_source    = bool
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
            trust_workstation_source    = bool
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
          deploy = object({
            docker = object({
              enabled = bool
              docker_users = list(string)
            }) 
          })
          vulnerable = object({
            docker = object({
              log4j_app = object({
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
            trust_workstation_source    = bool
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
            trust_workstation_source    = bool
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
          deploy = object({
            docker = object({
              enabled = bool
              docker_users = list(string)
            }) 
          })
          vulnerable = object({
            docker = object({
              log4j_app = object({
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
            cloudsql_app = object({
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
            trust_workstation_source    = bool
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
            trust_workstation_source    = bool
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
          custom_cluster_roles = list(object({
            enabled = bool
            name = string
            iam_user_names = list(string)
            rules = list(object({
              api_groups = list(string)
              resources = list(string)
              verbs = list(string)
              resource_names = list(string)
            }))
          }))
        })
        ssm = object({
          deploy = object({
            docker = object({
              enabled = bool
              docker_users = list(string)
            }) 
          })
          vulnerable = object({
            docker = object({
              log4j_app = object({
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
          reloader = object({
            enabled                     = bool
            ignore_namespaces           = list(string)
          })
          app = object({
            enabled                     = bool
            service_port                = number
            trust_attacker_source       = bool
            trust_target_source         = bool
            trust_workstation_source    = bool
            additional_trusted_sources  = list(string)
            image                       = string
            command                     = list(string)
            args                        = list(string)
            privileged                  = bool
            enable_dynu_dns             = bool
            dynu_dns_domain             = string
          })
          app-windows = object({
            enabled                     = bool
            service_port                = number
            trust_attacker_source       = bool
            trust_target_source         = bool
            trust_workstation_source    = bool
            additional_trusted_sources  = list(string)
            image                       = string
            command                     = list(string)
            args                        = list(string)
            privileged                  = bool
            enable_dynu_dns             = bool
            dynu_dns_domain             = string
          })
          vulnerable = object({
            log4j_app = object({
              enabled                     = bool
              service_port                = number
              trust_attacker_source       = bool
              trust_target_source         = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
              image                       = string
              command                     = list(string)
              args                        = list(string)
              privileged                  = bool
              enable_dynu_dns             = bool
              dynu_dns_domain             = string
            })
            voteapp = object({
              enabled                     = bool
              vote_service_port           = number
              result_service_port         = number
              trust_attacker_source       = bool
              trust_target_source         = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
            })
            rdsapp = object({
              enabled                     = bool
              service_port                = number
              trust_attacker_source       = bool
              trust_target_source         = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
              privileged                  = bool
              enable_dynu_dns             = bool
              dynu_dns_domain             = string
            })
            privileged_pod = object({
              enabled                     = bool
              service_port                = number
              trust_attacker_source       = bool
              trust_target_source         = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
              image                       = string
              command                     = list(string)
              args                        = list(string)
              privileged                  = bool
              enable_dynu_dns             = bool
              dynu_dns_domain             = string
            })
            root_mount_fs_pod = object({
              enabled                     = bool
              service_port                = number
              trust_attacker_source       = bool
              trust_target_source         = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
              image                       = string
              command                     = list(string)
              args                        = list(string)
              privileged                  = bool
              enable_dynu_dns             = bool
              dynu_dns_domain             = string
            })
            s3app = object({
              enabled                     = bool
              service_port                = number
              trust_attacker_source       = bool
              trust_target_source         = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
              privileged                  = bool
              admin_password              = string
              user_password               = string
              enable_dynu_dns             = bool
              dynu_dns_domain             = string
            })
            authapp = object({
              enabled                     = bool
              service_port                = number
              trust_attacker_source       = bool
              trust_target_source         = bool
              trust_workstation_source    = bool
              additional_trusted_sources  = list(string)
              privileged                  = bool
              admin_password              = string
              user_password               = string
              enable_dynu_dns             = bool
              dynu_dns_domain             = string
            })
          })
        })
        gcp = object({
          reloader = object({
            enabled                     = bool
            ignore_namespaces           = list(string)
          })
          app = object({
            enabled                       = bool
          })
          psp = object({
            enabled                       = bool
          })
          vulnerable = object({
            log4j_app = object({
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
          reloader = object({
            enabled                     = bool
            ignore_namespaces           = list(string)
          })
          app = object({
            enabled                       = bool
          })
          psp = object({
            enabled                       = bool
          })
          vulnerable = object({
            log4j_app = object({
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
            trust_workstation_source    = false
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
            trust_workstation_source    = false
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
          deploy = {
            docker = {
              enabled = false
              docker_users = []
            } 
          }
          vulnerable = {
            docker = {
              log4j_app = {
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
            ssh_private_key_path        = "/home/sshuser/.ssh/secret_key"
            ssh_public_key_path         = "/home/sshuser/.ssh/secret_key.pub"
            ssh_authorized_keys_path    = "/home/sshuser/.ssh/authorized_keys"
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
            trust_workstation_source    = false
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
            trust_workstation_source    = false
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
          deploy = {
            docker = {
              enabled = false
              docker_users = []
            } 
          }
          vulnerable = {
            docker = {
              log4j_app = {
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
            cloudsql_app        = {
              enabled                   = false
              listen_port               = 8091
            }
          }
          ssh_keys = {
            enabled                     = false
            ssh_private_key_path        = "/home/sshuser/.ssh/secret_key"
            ssh_public_key_path         = "/home/sshuser/.ssh/secret_key.pub"
            ssh_authorized_keys_path    = "/home/sshuser/.ssh/authorized_keys"
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
            trust_workstation_source    = false
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
            trust_workstation_source    = false
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
          custom_cluster_roles = []
        }
        ssm = {
          deploy = {
            docker = {
              enabled = false
              docker_users = []
            } 
          }
          vulnerable = {
            docker = {
              log4j_app = {
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
            ssh_private_key_path        = "/home/sshuser/.ssh/secret_key"
            ssh_public_key_path         = "/home/sshuser/.ssh/secret_key.pub"
            ssh_authorized_keys_path    = "/home/sshuser/.ssh/authorized_keys"
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
          reloader = {
            enabled                       = false
            ignore_namespaces             = []
          }
          app = {
            enabled                       = false
          }
          psp = {
            enabled                       = false
          }
          vulnerable = {
            log4j_app = {
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
          reloader = {
            enabled                     = false
            ignore_namespaces           = []
          }
          app = {
            enabled                     = false
            service_port                = 8000
            trust_attacker_source       = false
            trust_target_source         = false
            trust_workstation_source    = false
            additional_trusted_sources  = []
            image                       = "nginx:latest"
            command                     = ["tail"]
            args                        = ["-f", "/dev/null"]
            privileged                  = false
            enable_dynu_dns             = false
            dynu_dns_domain             = null
          }
          app-windows = {
            enabled                     = false
            service_port                = 8000
            trust_attacker_source       = false
            trust_target_source         = false
            trust_workstation_source    = false
            additional_trusted_sources  = []
            image                       = "mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022"
            command                     = [
                "powershell.exe",
                "-command",
                "Add-WindowsFeature Web-Server; Invoke-WebRequest -UseBasicParsing -Uri 'https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.6/ServiceMonitor.exe' -OutFile 'C:\\ServiceMonitor.exe'; echo '<html><body><br/><br/><H1>Our first pods running on Windows managed node groups! Powered by Windows Server LTSC 2022.<H1></body><html>' > C:\\inetpub\\wwwroot\\iisstart.htm; C:\\ServiceMonitor.exe 'w3svc'; "
            ]
            args                        = []
            privileged                  = false
            enable_dynu_dns             = false
            dynu_dns_domain             = null
          }
          vulnerable = {
            log4j_app = {
              enabled                     = false
              service_port                = 8000
              trust_attacker_source       = false
              trust_target_source         = false
              trust_workstation_source    = false
              additional_trusted_sources  = []
              image                       = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
              command                     = ["java"]
              args                        = ["-jar", "/app/spring-boot-application.jar"]
              privileged                  = false
              enable_dynu_dns             = false
              dynu_dns_domain             = null
            }
            voteapp = {
              enabled                     = false
              vote_service_port           = 8001
              result_service_port         = 8002
              trust_attacker_source       = false
              trust_target_source         = false
              trust_workstation_source    = false
              additional_trusted_sources  = []
            }

            rdsapp = {
              enabled                     = false
              service_port                = 8000
              trust_attacker_source       = false
              trust_target_source         = false
              trust_workstation_source    = false
              additional_trusted_sources  = []
              privileged                  = false
              enable_dynu_dns             = false
              dynu_dns_domain             = null
            }
            privileged_pod = {
              enabled                     = false
              service_port                = 8003
              trust_attacker_source       = false
              trust_target_source         = false
              trust_workstation_source    = false
              additional_trusted_sources  = []
              image                       = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
              command                     = ["java"]
              args                        = ["-jar", "/app/spring-boot-application.jar"]
              privileged                  = true
              enable_dynu_dns             = false
              dynu_dns_domain             = null
            }
            root_mount_fs_pod = {
              enabled                     = false
              service_port                = 8004
              trust_attacker_source       = false
              trust_target_source         = false
              trust_workstation_source    = false
              additional_trusted_sources  = []
              image                       = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
              command                     = ["java"]
              args                        = ["-jar", "/app/spring-boot-application.jar"]
              privileged                  = false
              enable_dynu_dns             = false
              dynu_dns_domain             = null
            }
            s3app = {
              enabled                     = false
              service_port                = 8000
              trust_attacker_source       = false
              trust_target_source         = false
              trust_workstation_source    = false
              additional_trusted_sources  = []
              privileged                  = false
              admin_password              = null
              user_password               = null
              enable_dynu_dns             = false
              dynu_dns_domain             = null
            }
            authapp = {
              enabled                     = false
              service_port                = 8000
              trust_attacker_source       = false
              trust_target_source         = false
              trust_workstation_source    = false
              additional_trusted_sources  = []
              privileged                  = false
              admin_password              = null
              user_password               = null
              enable_dynu_dns             = false
              dynu_dns_domain             = null
            }
          }
        }
        azure = {
          reloader = {
            enabled                       = false
            ignore_namespaces             = []
          }
          app = {
            enabled                       = false
          }
          psp = {
            enabled                       = false
          }
          vulnerable = {
            log4j_app = {
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