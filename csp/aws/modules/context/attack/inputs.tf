############################
# Context
############################

variable "config" {
  type = object({
          context = object({
            attacker = object({
                config = object({
                    protonvpn = object({
                        user        = string
                        password    = string
                        tier        = string
                        server      = string
                        protocol    = string
                    })
                    cryptomining = object({
                        cloud = object({
                            wallet = string
                        })
                        host = object({
                            user = string
                        })
                    })
                })
                responders = object({
                    http = object({
                        port  = number
                    })
                    reverseshell = object({
                        port  = number
                    })
                    log4shell = object({
                        http = object({
                          port = number
                        })
                        ldap = object({
                          port = number
                        })
                    })
                    portforwarder_server = object({
                        port = number
                    })
                })
                payloads = object({
                    reverseshell = string
                    log4shell = string
                })
                instances = object({
                    reverseshell = any
                    log4shell = any
                    portforwarder = any
                    codecov = any
                })
            })
            target = object({
                credentials = object({
                    compromised = object({
                        aws = any
                    })
                })
                listeners = object({
                  log4shell = object({
                      http = object({
                          port = number
                      })
                  })
                  portforwarder = object({
                      ports = any
                  })
                })
                instances = object({
                    reverseshell = any
                    log4shell = any
                    portforwarder = any
                    codecov = any
                })
            })
        })
    })

  default = {
    context = {
      attacker = {
        config = {
          protonvpn = {
            user        = null
            password    = null
            tier        = null
            server      = null
            protocol    = null
          }
          cryptomining = {
            cloud = {
              wallet = null
            }
            host = {
              user = null
            }
          }
        }
        responders = {
          http = {
            port  = 8000
          }
          reverseshell = {
              port  = 4444
          },
          log4shell = {
              http = {
                port = 8080
              }
              ldap = {
                port = 1389
              }
          }
          portforwarder_server = {
            port = 8888
          }
        }
        payloads = {
          reverseshell =  <<-EOT
                          touch /tmp/pwned_reverseshell
                          EOT
          log4shell =  <<-EOT
                          touch /tmp/pwned_log4shell
                          EOT
        }
        instances = {
          reverseshell = null
          log4shell = null
          portforwarder = null
          codecov = null
        }
      }
      target = {
        credentials = {
          compromised = {
            aws = null
          }
        }
        listeners = {
          reverseshell = {
              port  = 4444
          },
          log4shell = {
              http = {
                port = 8000
              }
          }
          portforwarder = {
            ports = [{
              src_port      = 80
              dst_port      = 4444
              dst_ip        = "127.0.0.1"                  
              description   = "sample port forward - replace destination ip with attacker ip"
            }]
          }
        }
        instances = {
          reverseshell = null
          log4shell = null
          portforwarder = null
          codecov = null
        }
      }
    }
  }
}

# simulation attacker target
variable "target_context_credentials_compromised_aws" {
  type = any
  description = "credentials to use in compromised keys attack"
  default = {}
}

variable "attacker_context_config_protonvpn_user" {
  type = string
  description = "protonvpn user"
  default = ""
}

variable "attacker_context_config_protonvpn_password" {
  type = string
  description = "protonvpn password"
  default = ""
}

variable "attacker_context_config_protonvpn_tier" {
  type = number
  description = "protonvpn tier (0=free, 1=basic, 2=pro, 3=visionary)"
  default = 0
}

variable "attacker_context_config_protonvpn_server" {
  type = string
  description = "protonvpn server (RANDOM, AU, CR, IS, JP, JP-FREE, LV, NL, NL-FREE, NZ, SG, SK, US, US-NJ, US-FREE,...); see https://api.protonmail.ch/vpn/logicals"
  default = "RANDOM"
}

variable "attacker_context_config_protonvpn_protocol" {
  type = string
  description = "protonvpn protocol"
  default = "udp"
}

variable "attacker_context_config_cryptomining_cloud_wallet" {
  type = string
  description = "cloud cryptomining wallet"
  default = ""
}

variable "attacker_context_config_cryptomining_host_user" {
  type = string
  description = "host cryptomining user"
  default = ""
}

variable "attacker_context_responder_http_port" {
  description = "http get/post capture server used for codecov"
  type = number
  default = 8444
}

variable "attacker_context_payload_reverseshell" {
  description = "the payload to send after reverse shell connection"
  type = string
  default = <<-EOT
  touch /tmp/pwned
  EOT
}

variable "attacker_context_responder_reverseshell_port" {
  description = "the payload to send after reverse shell connection"
  type = number
  default = 4444
}

variable "attacker_context_responder_log4shell_http_port" {
  description = "attacker http port used in log4shell attack"
  type = number
  default = 8080
}
variable "attacker_context_responder_log4shell_ldap_port" {
  description = "attacker ldap port used in log4shell attack"
  type = number
  default = 1389
}

variable "target_context_listener_log4shell_http_port" {
  description = "attacker http port used in codecov attack"
  type = number
  default = 8080
}

variable "attacker_context_payload_log4shell" {
  type = string
  description = "bash payload to run on target"
  default = <<-EOT
    touch /tmp/log4shell_pwned
    EOT
}

variable "attacker_context_responder_portforward_server_port" {
  type = number
  description = "attacker port forward server port"
  default = 8888
}

variable "target_context_listener_portforward_ports" {
  type = list(object({
      src_port      = number
      dst_port      = number
      dst_ip        = string
      description   = string
    }))
  description = "list of ports forward through attacker port forward server"
  default = []
}

variable "attacker_context_instance_reverseshell" {
  type = list
  description = "attacker reverse shell instance details"
  default = []
}

variable "attacker_context_instance_http" {
  type = list
  description = "attacker http listener instance details"
  default = []
}

variable "attacker_context_instance_log4shell" {
  type = list
  description = "attacker log4shell instance details"
  default = []
}

variable "attacker_context_instance_portforward" {
  type = list
  description = "attacker port forward instance details"
  default = []
}

variable "target_context_instance_reverseshell" {
  type = list
  description = "target reveser shell instance details"
  default = []
}

variable "target_context_instance_log4shell" {
  type = list
  description = "target log4shell instance details"
  default = []
}

variable "target_context_instance_portforward" {
  type = list
  description = "target port forward instance details"
  default = []
}