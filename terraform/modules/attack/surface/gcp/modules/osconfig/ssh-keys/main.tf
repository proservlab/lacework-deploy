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
    MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
    check_package_manager() {
        pgrep -f "apt" || pgrep -f "dpkg" || pgrep -f "yum" || pgrep -f "rpm"
    }
    while check_package_manager; do
        log "Waiting for package manager to be available..."
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
    MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
    check_package_manager() {
        pgrep -f "apt" || pgrep -f "dpkg" || pgrep -f "yum" || pgrep -f "rpm"
    }
    while check_package_manager; do
        log "Waiting for package manager to be available..."
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
# GCP OSCONFIG PUBLIC
#####################################################

module "osconfig-public" {
  source            = "../../../../../common/gcp/osconfig/base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.public_tag
  base64_payload    = local.base64_payload_public
}

#####################################################
# GCP OSCONFIG PRIVATE
#####################################################

module "osconfig-public" {
  source            = "../../../../../common/gcp/osconfig/base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.private_tag
  base64_payload    = local.base64_payload_private
}