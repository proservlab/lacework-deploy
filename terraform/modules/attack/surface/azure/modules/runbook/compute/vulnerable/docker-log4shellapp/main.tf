locals {
    image = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
    name = "log4shell"
    listen_port=var.listen_port
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
    log "Checking for docker..."
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(which docker)"
    if [[ `sudo docker ps | grep ${local.name}` ]]; then docker stop ${local.name}; fi
    log "$(echo 'docker run -d --name ${local.name} -v /tmp:/tmp --rm -p ${local.listen_port}:8080 ${local.image}')"
    docker run -d --name ${local.name} -v /tmp:/tmp --rm -p ${local.listen_port}:8080 ${local.image} >> $LOGFILE 2>&1
    docker ps -a >> $LOGFILE 2>&1
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