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
    LOGFILE=/tmp/osconfig_attacksurface_agentless_public_key.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
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
    LOGFILE=/tmp/osconfig_attacksurface_agentless_private_key.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
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

data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

resource "google_os_config_os_policy_assignment" "deploy-secret-ssh-private" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "osconfig-deploy-secret-ssh-private-${var.environment}-${var.deployment}"
  description = "Deploy secret ssh private key"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = var.private_label
    }

    inventories {
      os_short_name = "ubuntu"
    }

    inventories {
      os_short_name = "debian"
    }

  }

  os_policies {
    id   = "osconfig-deploy-secret-ssh-private-${var.environment}-${var.deployment}"
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
            script           = "echo '${local.base64_payload_private}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash - && exit 100"
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

resource "google_os_config_os_policy_assignment" "deploy-secret-ssh-public" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "osconfig-deploy-secret-ssh-public-${var.environment}-${var.deployment}"
  description = "Deploy secret ssh public key"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = var.public_label
    }

    inventories {
      os_short_name = "ubuntu"
    }

    inventories {
      os_short_name = "debian"
    }

  }

  os_policies {
    id   = "deploy-secret-ssh-public-${var.environment}-${var.deployment}"
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
            script           = "echo '${local.base64_payload_public}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash - && exit 100"
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