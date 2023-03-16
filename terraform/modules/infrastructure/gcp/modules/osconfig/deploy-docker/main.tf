locals {
    payload = <<-EOT
    LOGFILE=/tmp/osconfig_deploy_docker.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Checking for docker..."
    if ! which docker; then
        log "docker not found installation required"
        sudo apt-get remove -y docker docker-engine docker.io containerd runc
        sudo apt-get update
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-compose-plugin
    fi
    log "docker path: $(which docker)"
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
  
  name        = "osconfig-deploy-docker-${var.environment}-${var.deployment}"
  description = "Deploy docker"
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
    id   = "osconfig-deploy-docker-${var.environment}-${var.deployment}"
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