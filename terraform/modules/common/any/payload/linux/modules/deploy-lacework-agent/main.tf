locals {
    tool = "lacework"
    setup_lacework_agent = templatefile("${path.module}/resources/setup_lacework_agent.sh", {
        LaceworkInstallPath="/var/lib/lacework"
        LaceworkTempPath=var.inputs["lacework_agent_temp_path"]
        Tags=jsonencode(var.inputs["lacework_agent_tags"])
        Hash=""
        Serverurl=var.inputs["lacework_server_url"]
        Token=try(length(var.inputs["lacework_agent_access_token"]), "false") != "false" ? var.inputs["lacework_agent_access_token"] : lacework_agent_access_token.agent[0].token
    })

    payload = <<-EOT
    log "Starting..."
    if [ -f /var/lib/lacework/config/config.json ] && pgrep datacollector > /dev/null; then
        log "lacework already installed - nothing to do"
    else
        log "lacework not installed - installing..."
        echo '${base64encode(local.setup_lacework_agent)}' | base64 -d | /bin/bash -
    fi
    log "done."
    EOT
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        if [ -f /var/lib/lacework/config/config.json ]; then
            log "${local.tool} found no installation required"; 
            exit 0; 
        fi
        EOT
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        if [ -f /var/lib/lacework/config/config.json ]; then
            log "${local.tool} found no installation required"; 
            exit 0; 
        fi
        EOT
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}

#####################################################
# LACEWORK AGENT
#####################################################

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

resource "lacework_agent_access_token" "agent" {
    count = try(length(var.inputs["lacework_agent_access_token"]), "false") != "false" ? 0 : 1
    name = "endpoint-agent-access-token-${random_string.this.id}-${var.inputs["environment"]}-${var.inputs["deployment"]}"
}