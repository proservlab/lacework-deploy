locals {
    lacework_install_path = "/var/lib/lacework"
    lacework_config_path = "${local.lacework_install_path}/config.json"
    payload = <<-EOT
    LACEWORK_INSTALL_PATH="${local.lacework_install_path}"
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
    log "Checking for lacework..."
    
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
    resource_name = "${replace(substr(var.tag,0,35), "_", "-")}-${var.environment}-${var.deployment}-${random_string.this.id}"
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