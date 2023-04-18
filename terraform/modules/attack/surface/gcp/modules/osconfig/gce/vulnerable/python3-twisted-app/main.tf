
locals {
    listen_port=var.listen_port
    payload = <<-EOT
    LOGFILE=/tmp/ssm_exec_vuln_python3_twisted_app_target.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    screen -ls | grep vuln_python3_twisted_app_target | cut -d. -f1 | awk '{print $1}' | xargs kill
    truncate -s 0 /tmp/vuln_python3_twisted_app_target.log

    if ! which pip3; then
      log "pip3 not found - install required"
      if which apt; then
        log "installing pip3"
        apt update && apt-get install python3-pip
        log "pip3 installed"
      else
        log "unsupported installation of pip3"
      fi
    fi

    if which apt && apt list | grep "python3-twisted" | grep "18.9.0-11ubuntu0.20.04"; then
    
        mkdir -p /vuln_python3_twisted_app
        cd /vuln_python3_twisted_app
        echo ${local.app_py_base64} | base64 -d > app.py
        echo ${local.requirements_base64} | base64 -d > requirements.txt
        log "installing requirements..."
        python3 -m pip install -r requirements.txt >> $LOGFILE 2>&1
        log "requirements installed"

        screen -d -L -Logfile /tmp/vuln_python3_twisted_app_target.log -S vuln_python3_twisted_app_target -m python3 /vuln_python3_twisted_app/app.py
        screen -S vuln_python3_twisted_app_target -X colon "logfile flush 0^M"
        log 'waiting 30 minutes...';
        sleep 1800
        screen -ls | grep vuln_python3_twisted_app_target | cut -d. -f1 | awk '{print $1}' | xargs kill
    else
        log "python twisted vulnerability required the following package installed:"
        log "python3-twisted/focal-updates,focal-security,now 18.9.0-11ubuntu0.20.04.1"
    fi
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
    app_py_base64 = base64encode(templatefile(
                "${path.module}/resources/app.py",
                {
                    listen_port = var.listen_port
                }))
    requirements_base64 = base64encode(templatefile(
                "${path.module}/resources/requirements.txt",
                {
                }))
}

#####################################################
# GCP OSCONFIG
#####################################################

locals {
  tag = [for k,v in var.label: replace(replace(k, "_", "-"),"osconfig-","")][0]
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