
locals {
    listen_port=var.listen_port
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
    screen -S vuln_python3_twisted_app_target -X quit
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
        screen -S vuln_python3_twisted_app_target -X quit
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