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
        enabled                   = bool
        runbook = object({
          target = object({
            execute = object({
              touch_file = object({
                enabled                     = bool
              })
            })
          })
        })
      })
      gcp = object({
        region                    = string
        project_id                = string
        enabled                   = bool
        osconfig = object({
          target = object({
            drop = object({
              malware = object({
                eicar = object({ 
                  enabled                     = bool
                  eicar_path                  = string
                })
              })
            })
            connect = object({
              badip = object({
                enabled                     = bool
                iplist_url                  = string
              })
              nmap_port_scan = object({
                enabled                     = bool
                nmap_scan_host              = string
                nmap_scan_ports             = list(number)
              })
              oast = object({
                enabled                     = bool
              })
              codecov = object({
                enabled                     = bool
                use_ssl                     = bool
                git_origin                  = string
                env_secrets                 = list(string)
                host_ip                     = string
                host_port                   = number
              })
              reverse_shell = object({
                enabled                     = bool
                host_ip                     = string
                host_port                   = number
              })
            })
            listener = object({
              port_forward = object({
                enabled                     = bool
                port_forwards               = list(object({
                                                src_port      = number
                                                dst_port      = number
                                                dst_ip        = string
                                                description   = string
                                              }))
              })
            })
            execute = object({
              docker_cpu_miner = object({
                enabled                     = bool
                nicehash_image              = string
                nicehash_name               = string
                nicehash_server             = string
                nicehash_user               = string
                minergate_name              = string
                minergate_image             = string
                minergate_server            = string
                minergate_user              = string
              })
            })
          })
          attacker = object({
            listener = object({
              http = object({
                enabled                     = bool
                listen_ip                   = string
                listen_port                 = number
              })
            })
            responder = object({
              reverse_shell = object({
                enabled                     = bool
                listen_ip                   = string
                listen_port                 = number
                payload                     = string
              })
              port_forward = object({
                enabled                     = bool
                listen_port                 = number
              })
            })
            execute = object({
              vuln_npm_app_attack = object({
                enabled                     = bool
                target_ip                   = string
                target_port                 = number
                payload                     = string
              })
              docker_log4shell_attack = object({
                enabled                     = bool
                attacker_http_port          = number
                attacker_ldap_port          = number
                attacker_ip                 = string
                target_ip                   = string
                target_port                 = number
                payload                     = string
              })
              docker_composite_compromised_credentials_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
              docker_composite_cloud_ransomware_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
              docker_composite_defense_evasion_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
              docker_composite_cloud_cryptomining_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
              docker_composite_host_cryptomining_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
            })
          })
        })
      })
      aws = object({
        region                    = string
        profile_name              = string
        enabled                   = bool
        ssm = object({
          target = object({
            drop = object({
              malware = object({
                eicar = object({ 
                  enabled                     = bool
                  eicar_path                  = string
                })
              })
            })
            connect = object({
              badip = object({
                enabled                     = bool
                iplist_url                  = string
              })
              nmap_port_scan = object({
                enabled                     = bool
                nmap_scan_host              = string
                nmap_scan_ports             = list(number)
              })
              oast = object({
                enabled                     = bool
              })
              codecov = object({
                enabled                     = bool
                use_ssl                     = bool
                git_origin                  = string
                env_secrets                 = list(string)
                host_ip                     = string
                host_port                   = number
              })
              reverse_shell = object({
                enabled                     = bool
                host_ip                     = string
                host_port                   = number
              })
            })
            listener = object({
              port_forward = object({
                enabled                     = bool
                port_forwards               = list(object({
                                                src_port      = number
                                                dst_port      = number
                                                dst_ip        = string
                                                description   = string
                                              }))
              })
            })
            execute = object({
              docker_cpu_miner = object({
                enabled                     = bool
                nicehash_image              = string
                nicehash_name               = string
                nicehash_server             = string
                nicehash_user               = string
                minergate_name              = string
                minergate_image             = string
                minergate_server            = string
                minergate_user              = string
              })
            })
          })
          attacker = object({
            listener = object({
              http = object({
                enabled                     = bool
                listen_ip                   = string
                listen_port                 = number
              })
            })
            responder = object({
              reverse_shell = object({
                enabled                     = bool
                listen_ip                   = string
                listen_port                 = number
                payload                     = string
              })
              port_forward = object({
                enabled                     = bool
                listen_port                 = number
              })
            })
            execute = object({
              vuln_npm_app_attack = object({
                enabled                     = bool
                target_ip                   = string
                target_port                 = number
                payload                     = string
              })
              docker_log4shell_attack = object({
                enabled                     = bool
                attacker_http_port          = number
                attacker_ldap_port          = number
                attacker_ip                 = string
                target_ip                   = string
                target_port                 = number
                payload                     = string
              })
              docker_composite_compromised_credentials_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
              docker_composite_cloud_ransomware_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
              docker_composite_defense_evasion_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
              docker_composite_cloud_cryptomining_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
              docker_composite_host_cryptomining_attack = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
              })
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
        enabled                   = false
        runbook = {
          target = {
            drop = {
              malware = {
                eicar = { 
                  enabled                     = false
                  eicar_path                  = "/tmp/eicar"
                }
              }
            }
            connect = {
              badip = {
                enabled                     = false
                iplist_url                  = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
              }
              nmap_port_scan = {
                enabled                     = false
                nmap_scan_host              = "portquiz.net"
                nmap_scan_ports             = [80,443,23,22,8080,3389,27017,3306,6379,5432,389,636,1389,1636]
              }
              oast = {
                enabled                     = false
              }
              codecov = {
                enabled                     = false
                use_ssl                     = false
                git_origin                  = "git@git.localhost:repo/repo.git"
                env_secrets                 = ["SECRET=supersecret123"]
                host_ip                     = null
                host_port                   = 8080
              }
              reverse_shell = {
                enabled                     = false
                host_ip                     = null
                host_port                   = 4444
              }
            }
            listener = {
              port_forward = {
                enabled                     = false
                port_forwards               = [{
                                                src_port      = 1234
                                                dst_port      = 4444
                                                dst_ip        = "127.0.0.1"
                                                description   = "Example"
                                              }]
              }
            }
            execute = {
              touch_file = {
                enabled           = false
              }
              docker_cpu_miner = {
                enabled                     = false
                nicehash_image              = "a2ncer/nheqminer_cpu:latest"
                nicehash_name               = "nicehash"
                nicehash_server             = "equihash.usa.nicehash.com:3357"
                nicehash_user               = null
                minergate_name              = "minerd"
                minergate_image             = "mkell43/minerd"
                minergate_server            = "stratum+tcp://eth.pool.minergate.com:45791"
                minergate_user              = null
              }
            }
          }
          attacker = {
            listener = {
              http = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = 8080
              }
              port_forward = {
                enabled                     = false
                port_forwards               = [{
                                                src_port      = 1234
                                                dst_port      = 4444
                                                dst_ip        = "127.0.0.1"
                                                description   = "Example"
                                              }]
              }
            }
            responder = {
              reverse_shell = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = "4444"
                payload                     = "touch /tmp/pwned"
              }
              port_forward = {
                enabled                     = false
                listen_port                 = 8888
              }
            }
            execute = {
              vuln_npm_app_attack = {
                enabled                     = false
                target_ip                   = null
                target_port                 = 8089
                payload                     = "touch /tmp/vuln_npm_app_pwned"
              }
              docker_log4shell_attack = {
                enabled                     = false
                attacker_http_port          = 8088
                attacker_ldap_port          = 1389
                attacker_ip                 = null
                target_ip                   = null
                target_port                 = null
                payload                     = "touch /tmp/log4shell_pwned"
              }
              docker_composite_compromised_credentials_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_cloud_ransomware_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_defense_evasion_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_cloud_cryptomining_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_host_cryptomining_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              }
            }
          }
        }
      }
      gcp = {
        region                    = "us-central1"
        project_id                = null
        enabled                   = false
        osconfig = {
          target = {
            drop = {
              malware = {
                eicar = { 
                  enabled                     = false
                  eicar_path                  = "/tmp/eicar"
                }
              }
            }
            connect = {
              badip = {
                enabled                     = false
                iplist_url                  = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
              }
              nmap_port_scan = {
                enabled                     = false
                nmap_scan_host              = "portquiz.net"
                nmap_scan_ports             = [80,443,23,22,8080,3389,27017,3306,6379,5432,389,636,1389,1636]
              }
              oast = {
                enabled                     = false
              }
              codecov = {
                enabled                     = false
                use_ssl                     = false
                git_origin                  = "git@git.localhost:repo/repo.git"
                env_secrets                 = ["SECRET=supersecret123"]
                host_ip                     = null
                host_port                   = 8080
              }
              reverse_shell = {
                enabled                     = false
                host_ip                     = null
                host_port                   = 4444
              }
            }
            listener = {
              port_forward = {
                enabled                     = false
                port_forwards               = [{
                                                src_port      = 1234
                                                dst_port      = 4444
                                                dst_ip        = "127.0.0.1"
                                                description   = "Example"
                                              }]
              }
            }
            execute = {
              docker_cpu_miner = {
                enabled                     = false
                nicehash_image              = "a2ncer/nheqminer_cpu:latest"
                nicehash_name               = "nicehash"
                nicehash_server             = "equihash.usa.nicehash.com:3357"
                nicehash_user               = null
                minergate_name              = "minerd"
                minergate_image             = "mkell43/minerd"
                minergate_server            = "stratum+tcp://eth.pool.minergate.com:45791"
                minergate_user              = null
              }
            }
          }
          attacker = {
            listener = {
              http = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = 8080
              }
              port_forward = {
                enabled                     = false
                port_forwards               = [{
                                                src_port      = 1234
                                                dst_port      = 4444
                                                dst_ip        = "127.0.0.1"
                                                description   = "Example"
                                              }]
              }
            }
            responder = {
              reverse_shell = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = "4444"
                payload                     = "touch /tmp/pwned"
              }
              port_forward = {
                enabled                     = false
                listen_port                 = 8888
              }
            }
            execute = {
              vuln_npm_app_attack = {
                enabled                     = false
                target_ip                   = null
                target_port                 = 8089
                payload                     = "touch /tmp/vuln_npm_app_pwned"
              }
              docker_log4shell_attack = {
                enabled                     = false
                attacker_http_port          = 8088
                attacker_ldap_port          = 1389
                attacker_ip                 = null
                target_ip                   = null
                target_port                 = null
                payload                     = "touch /tmp/log4shell_pwned"
              }
              docker_composite_compromised_credentials_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_cloud_ransomware_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_defense_evasion_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_cloud_cryptomining_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_host_cryptomining_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              }
            }
          }
        }
      }
      aws = {
        region                    = "us-east-1"
        profile_name              = null
        enabled                   = false
        ssm = {
          target = {
            drop = {
              malware = {
                eicar = { 
                  enabled                     = false
                  eicar_path                  = "/tmp/eicar"
                }
              }
            }
            connect = {
              badip = {
                enabled                     = false
                iplist_url                  = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
              }
              nmap_port_scan = {
                enabled                     = false
                nmap_scan_host              = "portquiz.net"
                nmap_scan_ports             = [80,443,23,22,8080,3389,27017,3306,6379,5432,389,636,1389,1636]
              }
              oast = {
                enabled                     = false
              }
              codecov = {
                enabled                     = false
                use_ssl                     = false
                git_origin                  = "git@git.localhost:repo/repo.git"
                env_secrets                 = ["SECRET=supersecret123"]
                host_ip                     = null
                host_port                   = 8080
              }
              reverse_shell = {
                enabled                     = false
                host_ip                     = null
                host_port                   = 4444
              }
            }
            listener = {
              port_forward = {
                enabled                     = false
                port_forwards               = [{
                                                src_port      = 1234
                                                dst_port      = 4444
                                                dst_ip        = "127.0.0.1"
                                                description   = "Example"
                                              }]
              }
            }
            execute = {
              docker_cpu_miner = {
                enabled                     = false
                nicehash_image              = "a2ncer/nheqminer_cpu:latest"
                nicehash_name               = "nicehash"
                nicehash_server             = "equihash.usa.nicehash.com:3357"
                nicehash_user               = null
                minergate_name              = "minerd"
                minergate_image             = "mkell43/minerd"
                minergate_server            = "stratum+tcp://eth.pool.minergate.com:45791"
                minergate_user              = null
              }
            }
          }
          attacker = {
            listener = {
              http = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = 8080
              }
              port_forward = {
                enabled                     = false
                port_forwards               = [{
                                                src_port      = 1234
                                                dst_port      = 4444
                                                dst_ip        = "127.0.0.1"
                                                description   = "Example"
                                              }]
              }
            }
            responder = {
              reverse_shell = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = "4444"
                payload                     = "touch /tmp/pwned"
              }
              port_forward = {
                enabled                     = false
                listen_port                 = 8888
              }
            }
            execute = {
              vuln_npm_app_attack = {
                enabled                     = false
                target_ip                   = null
                target_port                 = 8089
                payload                     = "touch /tmp/vuln_npm_app_pwned"
              }
              docker_log4shell_attack = {
                enabled                     = false
                attacker_http_port          = 8088
                attacker_ldap_port          = 1389
                attacker_ip                 = null
                target_ip                   = null
                target_port                 = null
                payload                     = "touch /tmp/log4shell_pwned"
              }
              docker_composite_compromised_credentials_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_cloud_ransomware_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_defense_evasion_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_cloud_cryptomining_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              },
              docker_composite_host_cryptomining_attack = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
              }
            }
          }
        }
      }
    }
  }
}