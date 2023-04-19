
locals {
    repo = "https://github.com/ForbiddenProgrammer/CVE-2021-21315-PoC"
    listen_port=var.listen_port
    payload = <<-EOT
    LOGFILE=/tmp/osconfig_exec_vuln_npm_app_target.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    screen -ls | grep vuln_npm_app_target | cut -d. -f1 | awk '{print $1}' | xargs kill
    truncate -s 0 /tmp/vuln_npm_app_target.log
    log "checking for git..."
    while ! which git; do
        log "git not found - waiting"
        sleep 10
    done
    log "git: $(which git)"

    apt-get update && \
    apt-get install nodejs npm && \
    rm -rf /vuln_npm_app_target && \
    mkdir /vuln_npm_app_target && \
    cd /vuln_npm_app_target && \
    git clone ${local.repo} && \
    cd CVE-2021-21315-PoC && \
    echo ${local.index_js_base64} | base64 -d > index.js
    npm install >> $LOGFILE 2>&1

    screen -d -L -Logfile /tmp/vuln_npm_app_target.log -S vuln_npm_app_target -m npm start --prefix /vuln_npm_app_target/CVE-2021-21315-PoC
    screen -S vuln_npm_app_target -X colon "logfile flush 0^M"
    log 'waiting 10 minutes...';
    sleep 600
    screen -ls | grep vuln_npm_app_target | cut -d. -f1 | awk '{print $1}' | xargs kill
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
    index_js_base64 = base64encode(templatefile(
                "${path.module}/resources/index.js",
                {
                    listen_port = var.listen_port
                }))
}

#####################################################
# GCP OSCONFIG
#####################################################



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
  
  name        = "${var.tag}-${var.environment}-${var.deployment}-${random_string.this.id}"
  description = "Attack automation"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = jsondecode(<<-EOT
                            { 
                              "${var.tag}": "true",
                              "deployment": "{var.deployment}",
                              "environment": "{var.environment}"
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
    id   = "${var.tag}-${var.environment}-${var.deployment}-${random_string.this.id}"
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