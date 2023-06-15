locals {
    setup_lacework_agent = templatefile("${path.module}/resources/setup_lacework_agent.sh", {
        LaceworkInstallPath="/var/lib/lacework"
        LaceworkTempPath=var.lacework_agent_temp_path
        Tags=jsonencode(var.lacework_agent_tags)
        Hash=""
        Serverurl=var.lacework_server_url
        Token=can(length(var.lacework_agent_access_token)) ? var.lacework_agent_access_token : lacework_agent_access_token.agent[0].token
    })

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
    log "starting..."
    if [ -f /var/lib/lacework/config/config.json ] && pgrep datacollector > /dev/null; then
        log "lacework already installed - nothing to do"
    else
        log "lacework not installed - installing..."
        echo '${base64encode(local.setup_lacework_agent)}' | base64 -d | /bin/bash -
    fi
    log "done."
    EOT
    base64_payload = base64encode(local.payload)
}

#####################################################
# LACEWORK AGENT
#####################################################

resource "lacework_agent_access_token" "agent" {
    count = can(length(var.lacework_agent_access_token)) ? 0 : 1
    name = "endpoint-aws-agent-access-token-${var.environment}-${var.deployment}"
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
            script           = "if echo '${sha256(local.base64_payload)} /tmp/payload_${var.tag}' | sha256sum --check --status; then exit 100; else exit 101; fi"
          }
          enforce {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
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