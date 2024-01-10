locals {
    attack_dir = "/hostcompromise"
    attack_script_name = "hostcompromise.sh"
    start_script_name = "delayed_start.sh"
    lock_file = "/tmp/delay_hostcompromise.lock"

    payload = <<-EOT
    LOCKFILE="${ local.lock_file }"
    if [ -e "$LOCKFILE" ]; then
        echo "Another instance of the script is already running. Exiting..."
        exit 1
    fi
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
    log "Checking for docker..."
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(which docker)"
    log "removing previous app directory"
    rm -rf ${local.attack_dir}
    log "creating app directory"
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.attack_script} | base64 -d > ${local.attack_script_name}
    echo ${local.start_script} | base64 -d > ${local.start_script_name}

    log "starting background delayed script start..."
    nohup /bin/bash ${local.start_script_name} >/dev/null 2>&1 &
    log "background job started"
    log "done."
    EOT
    base64_payload      = base64encode(local.payload)
    attack_script              = base64encode(templatefile(
                                "${path.module}/resources/${local.attack_script_name}",
                                {
                                    
                                }
                        ))
    start_script              = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script_name}",
                                {
                                    lock_file = local.lock_file
                                    attack_delay = var.attack_delay
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script_name
                                }
                        ))
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