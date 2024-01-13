locals {
    nmap_download = "https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/nmap?raw=true"
    nmap_path = "/tmp/nmap"
    nmap_ports = join(",",var.inputs["nmap_scan_ports"])
    nmap_scan_host = var.inputs["nmap_scan_host"]
    payload = <<-EOT
    log "scan target: ${local.nmap_scan_host} ${local.nmap_ports}"
    log "checking for nmap"
    if ! command -v nmap; then
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