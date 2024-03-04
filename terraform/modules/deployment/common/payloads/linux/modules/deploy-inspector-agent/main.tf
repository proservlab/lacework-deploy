locals {
    payload = <<-EOT
    log "Checking for /opt/aws/awsagent/bin/awsagent..."
    if [ ! -f /opt/aws/awsagent/bin/awsagent ]; then
        log "Inspector not found. Installing inspector agent..."
        wget https://inspector-agent.amazonaws.com/linux/latest/install -P /tmp 2>/dev/null || curl -O  https://inspector-agent.amazonaws.com/linux/latest/install -o /tmp/install
        /bin/bash /tmp/install >> $LOGFILE 2>&1
    else
        log "Inspector agent found - skipping"
    fi;
    log "Done."
    EOT
    base64_payload = templatefile("../../delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        if [ -f /opt/aws/awsagent/bin/awsagent ]; then
            log "Inspector agent found - skipping"
            exit 0;
        fi
        EOT
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        if [ -f /opt/aws/awsagent/bin/awsagent ]; then
            log "Inspector agent found - skipping"
            exit 0;
        fi
        EOT
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})
    
    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}