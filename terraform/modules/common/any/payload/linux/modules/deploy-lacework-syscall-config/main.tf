locals {
    tool = "lacework-sycall-config"
    lacework_install_path = "/var/lib/lacework"
    lacework_syscall_config_path = "${local.lacework_install_path}/config/syscall_config.yaml"
    syscall_config = file(var.inputs["syscall_config"])
    base64_syscall_config = base64encode(local.syscall_config)
    hash_syscall_config = sha256(local.syscall_config)
    payload = <<-EOT
    LACEWORK_INSTALL_PATH="${local.lacework_install_path}"
    LACEWORK_SYSCALL_CONFIG_PATH=${local.lacework_syscall_config_path}
    
    # Check if Lacework is pre-installed. If installed, add syscall_config.yaml.
    if [ -f "$LACEWORK_INSTALL_PATH/datacollector" ]; then
        log "Lacework agent is installed, adding syscall_config.yaml..."
        if echo "${local.hash_syscall_config}  $LACEWORK_SYSCALL_CONFIG_PATH" | sha256sum --check --status; then 
            log "Lacework syscall_config.yaml unchanged"; 
        else 
            log "Lacework syscall_config.yaml requires update"
            echo -n "${local.base64_syscall_config}" | base64 -d > $LACEWORK_SYSCALL_CONFIG_PATH
        fi
        log "Lacework agent is installed, adding disable aggregation config..."
        file_path="/var/lib/lacework/config/config.json"

        log "Checking for ebpf aggregate_events disabled..."
        grep -q '"ebpf"[[:space:]]*:[[:space:]]*{[[:space:]]*"aggregate_events"[[:space:]]*:[[:space:]]*"false"[[:space:]]*}' $file_path
        if [ $? -ne 0 ]; then
            log "ebpf aggregate_events not currently disabled..."
            grep -q '"ebpf"[[:space:]]*:[[:space:]]*{[^}]*}' $file_path
            if [ $? -eq 0 ]; then
                log "Found existing ebpf config - updating..."
                sed -i 's/"ebpf"[[:space:]]*:[[:space:]]*{[^}]*}/"ebpf": {"aggregate_events": "false"}/' $file_path
            else
                log "No existing ebpf config - appending..."
                sed -i '1s/{/{\n  "ebpf": {"aggregate_events": "false"},/' $file_path
            fi
        else
            log "ebpf aggregate_events already enabled."
        fi
    fi
    EOT
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
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