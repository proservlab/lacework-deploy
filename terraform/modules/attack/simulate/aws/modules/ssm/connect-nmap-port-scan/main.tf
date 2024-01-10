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

###########################
# SSM 
###########################

module "ssm" {
    source          = "../../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = local.base64_payload
}