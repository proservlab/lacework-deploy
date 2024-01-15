locals {
    image = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
    name = "log4shell"
    listen_port=var.inputs["listen_port"]
    payload = <<-EOT
    log "Checking for docker..."
    while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(command -v  docker)"
    if [[ `sudo docker ps | grep ${local.name}` ]]; then docker stop ${local.name}; fi
    log "$(echo 'docker run -d --name ${local.name} -v /tmp:/tmp --rm -p ${local.listen_port}:8080 ${local.image}')"
    docker run -d --name ${local.name} -v /tmp:/tmp --rm -p ${local.listen_port}:8080 ${local.image} >> $LOGFILE 2>&1
    docker ps -a >> $LOGFILE 2>&1
    log "done"
    EOT
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
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