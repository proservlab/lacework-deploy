
locals {
    listen_port=var.listen_port
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
    screen -S vuln_python3_twisted_app_target -X quit
    truncate -s 0 /tmp/vuln_python3_twisted_app_target.log

    if ! which pip3; then
      log "pip3 not found - install required"
      if which apt; then
        log "installing pip3"
        apt update && apt-get install python3-pip
        log "pip3 installed"
      else
        log "unsupported installation of pip3"
      fi
    fi

    if which apt && apt list | grep "python3-twisted" | grep "18.9.0-11ubuntu0.20.04"; then
    
        mkdir -p /vuln_python3_twisted_app
        cd /vuln_python3_twisted_app
        echo ${local.app_py_base64} | base64 -d > app.py
        echo ${local.requirements_base64} | base64 -d > requirements.txt
        log "installing requirements..."
        python3 -m pip install -r requirements.txt >> $LOGFILE 2>&1
        log "requirements installed"

        screen -d -L -Logfile /tmp/vuln_python3_twisted_app_target.log -S vuln_python3_twisted_app_target -m python3 /vuln_python3_twisted_app/app.py
        screen -S vuln_python3_twisted_app_target -X colon "logfile flush 0^M"
        log 'waiting 30 minutes...';
        sleep 1800
        screen -S vuln_python3_twisted_app_target -X quit
    else
        log "python twisted vulnerability required the following package installed:"
        log "python3-twisted/focal-updates,focal-security,now 18.9.0-11ubuntu0.20.04.1"
    fi
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
    app_py_base64 = base64encode(templatefile(
                "${path.module}/resources/app.py",
                {
                    listen_port = var.listen_port
                }))
    requirements_base64 = base64encode(templatefile(
                "${path.module}/resources/requirements.txt",
                {
                }))
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