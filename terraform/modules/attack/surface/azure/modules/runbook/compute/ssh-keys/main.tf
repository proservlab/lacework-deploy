# ssh key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

locals {
    ssh_private_key = base64encode(tls_private_key.ssh.private_key_pem)
    ssh_private_key_path = var.ssh_private_key_path
    ssh_public_key = base64encode(chomp(tls_private_key.ssh.public_key_openssh))
    ssh_public_key_path = var.ssh_public_key_path
    ssh_authorized_keys_path = var.ssh_authorized_keys_path

    payload_public = <<-EOT
    LOGFILE=/tmp/${var.public_tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
    check_apt() {
        pgrep -f "apt" || pgrep -f "dpkg"
    }
    while check_apt; do
        log "Waiting for apt to be available..."
        sleep 10
    done
    log "creating public key: ${local.ssh_public_key_path}"
    rm -rf ${local.ssh_public_key_path}
    mkdir -p ${dirname(local.ssh_public_key_path)}
    echo '${base64decode(local.ssh_public_key)}' > ${local.ssh_public_key_path}
    chmod 600 ${local.ssh_public_key_path}
    chown ubuntu:ubuntu ${local.ssh_public_key_path}
    log "public key: $(ls -l ${local.ssh_public_key_path})"
    log "done"
    EOT
    base64_payload_public = base64encode(local.payload_public)

    payload_private = <<-EOT
    LOGFILE=/tmp/${var.private_tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
    check_apt() {
        pgrep -f "apt" || pgrep -f "dpkg"
    }
    while check_apt; do
        log "Waiting for apt to be available..."
        sleep 10
    done
    log "creating private key: ${local.ssh_private_key_path}"
    rm -rf ${local.ssh_private_key_path}
    mkdir -p ${dirname(local.ssh_private_key_path)}
    echo '${base64decode(local.ssh_private_key)}' > ${local.ssh_private_key_path}
    chmod 600 ${local.ssh_private_key_path}
    chown ubuntu:ubuntu ${local.ssh_private_key_path}
    echo '${base64decode(local.ssh_public_key)}' >> ${local.ssh_authorized_keys_path}
    sort ${local.ssh_authorized_keys_path} | uniq > ${local.ssh_authorized_keys_path}.uniq
    mv ${local.ssh_authorized_keys_path}.uniq ${local.ssh_authorized_keys_path}
    rm -f ${local.ssh_authorized_keys_path}.uniq
    log "private key: $(ls -l ${local.ssh_private_key_path})"
    log "done"
    EOT
    base64_payload_private = base64encode(local.payload_private)
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

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

#####################################################
# RESOURCE GROUP RUNBOOK PUBLIC KEY
#####################################################

resource "azurerm_automation_runbook" "public_demo_rb" {
    name                    = "${var.public_tag}-${var.environment}-${var.deployment}-${random_string.this.id}"
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
                                base64_payload          = local.base64_payload_private
                                module_name             = basename(abspath(path.module))
                                tag                     = var.public_tag
                            })
}

resource "azurerm_automation_schedule" "public_hourly" {
  name                    = "${var.public_tag}-schedule-${var.environment}-${var.deployment}_${random_string.this.id}"
  resource_group_name     = var.resource_group.name
  automation_account_name = var.automation_account
  frequency               = "Hour"
  interval                = 1
  timezone                = "UTC"
  description             = "Run every hour"
  start_time              = timeadd(timestamp(), "10m")
}

resource "azurerm_automation_job_schedule" "public_demo_sched" {
    resource_group_name     = var.resource_group.name
    automation_account_name = var.automation_account
    schedule_name           = azurerm_automation_schedule.public_hourly.name
    runbook_name            = azurerm_automation_runbook.public_demo_rb.name
    depends_on              = [azurerm_automation_schedule.public_hourly]
}

#####################################################
# RESOURCE GROUP RUNBOOK PRIVATE KEY
#####################################################

resource "azurerm_automation_runbook" "private_demo_rb" {
    name                    = "${var.private_tag}-${var.environment}-${var.deployment}-${random_string.this.id}"
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
                                base64_payload          = local.base64_payload_private
                                module_name             = basename(abspath(path.module))
                                tag                     = var.private_tag
                            })
}

resource "azurerm_automation_schedule" "private_hourly" {
  name                    = "${var.private_tag}-schedule-${var.environment}-${var.deployment}_${random_string.this.id}"
  resource_group_name     = var.resource_group.name
  automation_account_name = var.automation_account
  frequency               = "Hour"
  interval                = 1
  timezone                = "UTC"
  description             = "Run every hour"
  start_time              = timeadd(timestamp(), "10m")
}

resource "azurerm_automation_job_schedule" "private_demo_sched" {
    resource_group_name     = var.resource_group.name
    automation_account_name = var.automation_account
    schedule_name           = azurerm_automation_schedule.private_hourly.name
    runbook_name            = azurerm_automation_runbook.private_demo_rb.name
    depends_on              = [azurerm_automation_schedule.private_hourly]
}