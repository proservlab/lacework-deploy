locals {
    attack_dir = "/guardduty"
    attack_script = "discovery_aws_instance_creds_tor.sh"
    start_script = "discovery_delayed_start.sh"
    payload = <<-EOT
    log "removing previous app directory"
    rm -rf ${local.attack_dir}
    log "creating app directory"
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.discovery} | base64 -d > ${local.attack_script}
    echo ${local.start} | base64 -d > ${local.start_script}
    while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "starting script..."
    /bin/bash ${local.start_script}
    
    log "done."
    EOT

    discovery       = base64encode(file(
                                "${path.module}/resources/${local.attack_script}", 
                            ))
    start           = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script}",
                                {
                                    attack_delay = var.inputs["attack_delay"]
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script
                                } 
                            ))

    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
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
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}