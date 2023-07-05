locals {
    nmap_download = "https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/nmap?raw=true"
    nmap_path = "/tmp/nmap"
    nmap_ports = join(",",var.nmap_scan_ports)
    nmap_scan_host = var.nmap_scan_host
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
    log "scan target: ${local.nmap_scan_host} ${local.nmap_ports}"
    log "checking for nmap"
    if ! which nmap; then
        log "nmap not found"
        log "downloading: ${local.nmap_download}"
        if [ -f ${local.nmap_path} ]; then
            curl -L -o ${local.nmap_path} ${local.nmap_download} >> $LOGFILE 2>&1
            chmod 755 ${local.nmap_path} >> $LOGFILE 2>&1
        fi
        log "using nmap: ${local.nmap_path}"
        ${local.nmap_path} -sS -p ${local.nmap_ports} ${local.nmap_scan_host} >> $LOGFILE 2>&1
    else
        nmap -sS -p ${local.nmap_ports} ${local.nmap_scan_host} >> $LOGFILE 2>&1
    fi
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
            
            script           = "if echo '${sha256(local.base64_payload)} /tmp/payload_${var.tag}' | sha256sum --check --status; then exit 100; else exit 101; fi"
          }
          enforce {
            interpreter      = "SHELL"
            
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