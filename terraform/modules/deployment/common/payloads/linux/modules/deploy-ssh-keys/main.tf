# ssh key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

locals {
    ssh_private_key = base64encode(tls_private_key.ssh.private_key_pem)
    ssh_private_key_path = var.inputs["ssh_private_key_path"]
    ssh_public_key = base64encode(chomp(tls_private_key.ssh.public_key_openssh))
    ssh_public_key_path = var.inputs["ssh_public_key_path"]
    ssh_authorized_keys_path = var.inputs["ssh_authorized_keys_path"]
    public_key_user = split("/", local.ssh_public_key_path)[1] == "root" ? "root" : split("/", local.ssh_public_key_path)[2]
    private_key_user = split("/", local.ssh_private_key_path)[1] == "root" ? "root" : split("/", local.ssh_private_key_path)[2]

    payload_public = <<-EOT
    log "starting script"
    log "creating public key: ${local.ssh_public_key_path}"
    log "adding user: ${local.public_key_user}..."
    adduser --gecos "" --disabled-password "${local.public_key_user}" || log "${local.public_key_user} user already exists"
    mkdir -p ${dirname(local.ssh_public_key_path)}
    echo '${base64decode(local.ssh_public_key)}' > ${local.ssh_public_key_path}
    chmod 600 ${local.ssh_public_key_path}
    chown ${local.public_key_user}:${local.public_key_user} ${local.ssh_public_key_path}
    echo '${base64decode(local.ssh_public_key)}' >> ${local.ssh_authorized_keys_path}
    sort ${local.ssh_authorized_keys_path} | uniq > ${local.ssh_authorized_keys_path}.uniq
    mv ${local.ssh_authorized_keys_path}.uniq ${local.ssh_authorized_keys_path}
    log "public key: $(ls -l ${local.ssh_public_key_path})"
    log "done"
    EOT
    base64_payload_public = templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["public_tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload_public
    }})

    payload_private = <<-EOT
    log "starting script"
    log "creating private key: ${local.ssh_private_key_path}"
    log "adding user: ${local.private_key_user}..."
    adduser --gecos "" --disabled-password "${local.private_key_user}" || log "${local.private_key_user} user already exists"
    mkdir -p ${dirname(local.ssh_private_key_path)}
    echo '${base64decode(local.ssh_private_key)}' > ${local.ssh_private_key_path}
    chmod 600 ${local.ssh_private_key_path}
    chown ${local.private_key_user}:${local.private_key_user} ${local.ssh_private_key_path}
    log "private key: $(ls -l ${local.ssh_private_key_path})"
    log "done"
    EOT
    base64_payload_private = templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["private_tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload_private
    }})

    outputs = {
        base64_payload_public = base64gzip(local.base64_payload_public)
        base64_uncompressed_payload_public = base64encode(local.base64_payload_public)
        base64_payload_private = base64gzip(local.base64_payload_private)
        base64_uncompressed_payload_private = base64encode(local.base64_payload_private)
        base64_uncompressed_payload_additional = []
    }
}