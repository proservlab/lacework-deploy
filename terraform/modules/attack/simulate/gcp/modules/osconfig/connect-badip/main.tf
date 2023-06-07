locals {
    iplist_url = var.iplist_url
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
    log "finding bad ip: ${local.iplist_url}"
    BADIP=$(curl -s ${local.iplist_url} | grep -v \"#\" | awk -v num_line=$((1 + $RANDOM % 1000)) 'NR == num_line' | tr -d \"\n\")
    log "found bad ip: $BADIP"
    ping -c 10 -w 5 $BADIP >> $LOGFILE 2>&1
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
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