locals {
    attack_dir = "/hostcompromise"
    attack_script_name = "hostcompromise.sh"
    start_script_name = "delayed_start.sh"
    lock_file = "/tmp/delay_hostcompromise.lock"

    payload = <<-EOT
    log "removing previous app directory"
    rm -rf ${local.attack_dir}
    log "creating app directory"
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.attack_script} | base64 -d > ${local.attack_script_name}
    echo ${local.start_script} | base64 -d > ${local.start_script_name}
    log "starting background delayed script start..."
    /bin/bash ${local.start_script_name}
    log "done."
    EOT
    
    attack_script              = base64encode(templatefile(
                                "${path.module}/resources/${local.attack_script_name}",
                                {
                                    # jndiexploit_url     = local.jndiexploit_url
                                    # image               = local.image
                                    # name                = local.name
                                    # attacker_ip         = var.inputs["attacker_ip"]
                                    # attacker_http_port  = var.inputs["attacker_http_port"]
                                    # attacker_ldap_port  = var.inputs["attacker_ldap_port"]
                                    # target_ip           = var.inputs["target_ip"]
                                    # target_port         = var.inputs["target_port"]
                                    # exec_type           = local.exec_type
                                    # base64_payload      = local.base64_log4shell_payload
                                    # reverse_shell_port  = var.inputs["reverse_shell_port"]
                                }
                        ))
    start_script              = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script_name}",
                                {
                                    lock_file = local.lock_file
                                    attack_delay = var.inputs["attack_delay"]
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script_name
                                }
                        ))

    base64_payload = templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        log "Checking for docker..."
        while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        log "docker path: $(command -v  docker)"
        EOT
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        log "Checking for docker..."
        while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        log "docker path: $(command -v  docker)"
        EOT
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
    }
}