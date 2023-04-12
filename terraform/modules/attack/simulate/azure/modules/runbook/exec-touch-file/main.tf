
locals {
    payload = <<-EOT
    LOGFILE=/tmp/runbook_attacker_touch_file.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "starting..."
    touch /tmp/runbook.txt
    log "done."
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

resource "azurerm_automation_runbook" "demo_rb" {
    name                    = "${var.tag}-runbook-${var.environment}-${var.deployment}"
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
  name                    = "${var.tag}-schedule-${var.environment}-${var.deployment}"
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