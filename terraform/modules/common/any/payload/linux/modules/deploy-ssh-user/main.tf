locals {
    password = try(length(var.inputs["password"]),"false") != "false" ? var.inputs["password"] :  random_password.password.result
    payload = <<-EOT
    log "starting script"
    log "Setting up user: ${var.inputs["username"]}"
    adduser --gecos "" --disabled-password ${var.inputs["username"]}
    log "Setting passwd: ${local.password}"
    echo '${var.inputs["username"]}:${local.password}' | chpasswd
    log "Adding user to allowed passwd auth in sshd_config.d"
    cat > /etc/ssh/sshd_config.d/common-user-passwd-auth.conf <<-EOF 
    Match User root,admin,test,guest,info,adm,mysql,user,administrator,oracle,ftp,pi,puppet,ansible,ec2-user,vagrant,azureuser
        PasswordAuthentication yes
        ForceCommand /bin/echo 'We talked about this guys. No SSH for you!'
    EOF
    cat > /etc/ssh/sshd_config.d/custom-user-passwd-auth.conf <<-EOF 
    Match User ${var.inputs["username"]}
        PasswordAuthentication yes
    EOF
    log "Restarting ssh service"
    service ssh reload
    log "Done."
    EOT
    base64_payload = templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        password = local.password
    }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}