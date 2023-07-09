resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}
locals {
    ssh_private_key = base64encode(tls_private_key.ssh.private_key_pem)
    ssh_private_key_path = "/home/ubuntu/.ssh/secret_key"
    ssh_public_key = base64encode(chomp(tls_private_key.ssh.public_key_openssh))
    ssh_public_key_path = "/home/ubuntu/.ssh/secret_key.pub"
    ssh_authorized_keys_path = "/home/ubuntu/.ssh/authorized_keys"

    payload_public = <<-EOT
    LOGFILE=/tmp/${var.public_tag}.log
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
    log "creating public key: ${local.ssh_public_key_path}"
    rm -rf ${local.ssh_public_key_path}
    echo '${base64decode(local.ssh_public_key)}' > ${local.ssh_public_key_path}
    chmod 600 ${local.ssh_public_key_path}
    chown ubuntu:ubuntu ${local.ssh_public_key_path}
    log "public key: $(ls -l ${local.ssh_public_key_path})"
    log "done"
    EOT
    base64_payload_public = base64encode(local.payload_public)

    payload_private = <<-EOT
    LOGFILE=/tmp/${var.private_tag}.log
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
    log "creating private key: ${local.ssh_private_key_path}"
    rm -rf ${local.ssh_private_key_path}
    echo '${base64decode(local.ssh_private_key)}' > ${local.ssh_private_key_path}
    chmod 600 ${local.ssh_private_key_path}
    chown ubuntu:ubuntu ${local.ssh_private_key_path}
    echo '${base64decode(local.ssh_public_key)}' >> ${local.ssh_authorized_keys_path}
    sort ${local.ssh_authorized_keys_path} | uniq > ${local.ssh_authorized_keys_path}.uniq
    mv ${local.ssh_authorized_keys_path}.uniq ${local.ssh_authorized_keys_path}
    rm -f ${local.ssh_authorized_keys_path}.uniq
    log "private key: $(ls -l ${local.ssh_private_key_path})"
    log "done"
    EOT
    base64_payload_private = base64encode(local.payload_private)
}

#####################################################
# GCP OSCONFIG
#####################################################

locals {
    public_resource_name = "${replace(var.public_tag, "_", "-")}-${var.environment}-${var.deployment}-${random_string.public.id}"
}

resource "random_string" "public" {
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

resource "google_os_config_os_policy_assignment" "public" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "${local.public_resource_name}"
  description = "Attack automation"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = jsondecode(<<-EOT
                            { 
                              "${var.public_tag}": "true",
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
    id   = "${local.public_resource_name}"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "run"
        exec {
          validate {
            interpreter      = "SHELL"
            
            script           = "/bin/bash -c 'echo ${local.base64_payload_public} | tee /tmp/payload_${var.public_tag} | base64 -d | /bin/bash - &' && exit 100"
          }
          enforce {
            interpreter      = "SHELL"
            
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

#####################################################
# GCP OSCONFIG PRIVATE
#####################################################

locals {
    private_resource_name = "${replace(var.private_tag, "_", "-")}-${var.environment}-${var.deployment}-${random_string.private.id}"
}


resource "random_string" "private" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

# data "google_compute_zones" "available" {
#   project     = var.gcp_project_id
#   region    = var.gcp_location
# }

resource "google_os_config_os_policy_assignment" "private" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "${local.private_resource_name}"
  description = "Attack automation"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = jsondecode(<<-EOT
                            { 
                              "${var.private_tag}": "true",
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
    id   = "${local.private_resource_name}"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "run"
        exec {
          validate {
            interpreter      = "SHELL"
            
            script           = "/bin/bash -c 'echo ${local.base64_payload_private} | tee /tmp/payload_${var.private_tag} | base64 -d | /bin/bash - &' && exit 100"
          }
          enforce {
            interpreter      = "SHELL"
            
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