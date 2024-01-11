locals {
    tool = "lacework-codeware-agent"
    lacework_install_path = "/var/lib/lacework"
    payload = <<-EOT
    LACEWORK_INSTALL_PATH="${local.lacework_install_path}"  
    
    # Check if Lacework is pre-installed. If installed, add code aware agent config.
    if [ -f "$LACEWORK_INSTALL_PATH/datacollector" ]; then
        log "Lacework agent is installed, adding code aware agent config..."
        file_path="/var/lib/lacework/config/config.json"
        
        log "Checking for codeaware agent config enable..."
        grep -q '"codeaware"[[:space:]]*:[[:space:]]*{[[:space:]]*"enable"[[:space:]]*:[[:space:]]*"all"[[:space:]]*}' $file_path
        if [ $? -ne 0 ]; then
            log "Code aware agent not currently enabled..."
            grep -q '"codeaware"[[:space:]]*:[[:space:]]*{[^}]*}' $file_path
            if [ $? -eq 0 ]; then
                log "Found existing codeaware config - updating..."
                sed -i 's/"codeaware"[[:space:]]*:[[:space:]]*{[^}]*}/"codeaware": {"enable": "all"}/' $file_path
            else
                log "No existing codeaware config - appending..."
                sed -i '1s/{/{\n  "codeaware": {"enable": "all"},/' $file_path
            fi
        else
            log "Code aware agent config already enabled."
        fi
    fi
    log "Done"
    EOT
    base64_payload = base64encode(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
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