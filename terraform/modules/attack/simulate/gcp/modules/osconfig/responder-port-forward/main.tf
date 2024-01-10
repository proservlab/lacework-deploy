locals {
    listen_port = var.listen_port
    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_port_forward.log
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
    killall -9 chisel
    truncate -s 0 /tmp/chisel.log
    log "checking for chisel..."
    while ! which chisel; do
        log "chisel not found - installing"
        curl https://i.jpillora.com/chisel! | bash
        sleep 10
    done
    log "chisel: $(which chisel)"
    /usr/local/bin/chisel server -v -p ${local.listen_port} > /tmp/chisel.log 2>&1 &
    log "waiting 10 minutes..."
    sleep 600
    log "wait done - terminating"
    killall -9 chisel
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

#####################################################
# GCP OSCONFIG
#####################################################

module "osconfig" {
  source            = "../../../../../common/gcp/osconfig/base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.tag
  base64_payload    = local.base64_payload
}