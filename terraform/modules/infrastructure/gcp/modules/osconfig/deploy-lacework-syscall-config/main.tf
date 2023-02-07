locals {
    lacework_install_path = "/var/lib/lacework"
    lacework_syscall_config_path = "${local.lacework_install_path}/config/syscall_config.yaml"
    syscall_config = file(var.syscall_config)
    base64_syscall_config = base64encode(local.syscall_config)
    hash_syscall_config = sha256(local.syscall_config)
    payload = <<-EOT
    set -e
    LACEWORK_INSTALL_PATH="${local.lacework_install_path}"
    LACEWORK_SYSCALL_CONFIG_PATH=${local.lacework_syscall_config_path}
    LOGFILE=/tmp/ssm_deploy_lacework_syscall.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Checking for lacework..."
    
    # Check if Lacework is pre-installed. If installed, add syscall_config.yaml.
    if [ -f "$LACEWORK_INSTALL_PATH/datacollector" ]; then
        log "Lacework agent is installed, adding syscall_config.yaml..."
        if echo "${local.hash_syscall_config}  $LACEWORK_SYSCALL_CONFIG_PATH" | sha256sum --check --status; then 
            log "Lacework syscall_config.yaml unchanged"; 
        else 
            log "Lacework syscall_config.yaml requires update"
            echo -n "${local.base64_syscall_config}" | base64 -d > $LACEWORK_SYSCALL_CONFIG_PATH
        fi
    fi
    EOT
    base64_payload = base64encode(local.payload)
}

data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

resource "google_os_config_os_policy_assignment" "install-lacework-agent" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "osconfig-deploy-lacework-syscall-config-${var.environment}-${var.deployment}"
  description = "Deploy lacework syscall config"
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
    id   = "osconfig-deploy-lacework-syscall-config-${var.environment}-${var.deployment}"
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