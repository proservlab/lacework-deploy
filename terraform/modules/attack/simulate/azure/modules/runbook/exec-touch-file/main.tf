
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

locals {
    automation_account_name = "development-automation"
}

data "azurerm_subscription" "current" {
}

resource "azurerm_role_definition" "run_command_vm" {
    name        = "RunCommandVM"
    scope       = data.azurerm_subscription.current.id
    description = "Allow stopping and starting VMs in the current subscription"

    permissions {
        actions     = [
                        "Microsoft.Network/*/read",
                        "Microsoft.Compute/*/read",
                        "Microsoft.Compute/virtualMachines/runCommand/action"
                        ]
        not_actions = []
    }
}

resource "azurerm_user_assigned_identity" "development_automation" {
    location            = var.resource_group.location
    resource_group_name = var.resource_group.name

    name = local.automation_account_name
}

data "azurerm_role_definition" "vm_contributor" {
    name = "Virtual Machine Contributor"
}

resource "azurerm_role_assignment" "development_automation" {
    scope              = data.azurerm_subscription.current.id
    role_definition_id = azurerm_role_definition.run_command_vm.role_definition_resource_id
    principal_id       = azurerm_user_assigned_identity.development_automation.principal_id
}

resource "azurerm_role_assignment" "vm_contributor" {
    scope              = data.azurerm_subscription.current.id
    role_definition_id = data.azurerm_role_definition.vm_contributor.role_definition_id
    principal_id       = azurerm_user_assigned_identity.development_automation.principal_id
}

resource "azurerm_resource_group_template_deployment" "ARMdeploy-automation-acct" {
    name                = "ARMdeploy-Automation-Start"
    resource_group_name = var.resource_group.name

    # "Incremental" ADDS the resource to already existing resources. "Complete" destroys all other resources and creates the new one
    deployment_mode     = "Incremental"

    # the parameters below can be found near the top of the ARM file
    parameters_content = jsonencode({
        "automationAccount_name" = {
            value = local.automation_account_name
        },
        "my_location" = {
            value = var.resource_group.location
        },
        "userAssigned_identity" = {
            value = azurerm_user_assigned_identity.development_automation.id
        }
    })
    # the actual ARM template file we will use
    template_content = file("${path.module}/user-id-template.json")
}

resource "azurerm_automation_module" "Azure-MI-Automation-module" {
    name                    = "Az.ManagedServiceIdentity"
    resource_group_name     = var.resource_group.name
    automation_account_name = local.automation_account_name

    module_link {
        uri = "https://www.powershellgallery.com/api/v2/package/Az.ManagedServiceIdentity/0.7.3"
    }
    depends_on = [
        azurerm_resource_group_template_deployment.ARMdeploy-automation-acct
    ]
}

resource "azurerm_automation_account" "development" {
    name                = "development"
    location            = var.resource_group.location
    resource_group_name = var.resource_group.name
    sku_name            = "Basic"

    identity {
        type = "UserAssigned"
        identity_ids = [azurerm_user_assigned_identity.development_automation.id]
    }
}

resource "azurerm_automation_runbook" "demo_rb" {
    name                    = "Demo-Runbook"
    location                = var.resource_group.location
    resource_group_name     = var.resource_group.name
    automation_account_name = azurerm_automation_account.development.name
    log_verbose             = "true"
    log_progress            = "true"
    description             = "This Run Book is a demo"
    runbook_type            = "Script"
    content                 = templatefile(pathexpand("${path.module}/runbooks/powershell/RunCommand.ps1"), {
                                subscription            = data.azurerm_subscription.current.subscription_id
                                resource_group          = var.resource_group.name
                                automation_account      = azurerm_user_assigned_identity.development_automation.principal_id
                                base64_payload          = local.base64_payload
                                module_name             = basename(abspath(path.module))
                            })
    depends_on = [
        azurerm_resource_group_template_deployment.ARMdeploy-automation-acct
    ]
}

resource "azurerm_automation_schedule" "hourly" {
  name                    = "Hourly"
  resource_group_name     = var.resource_group.name
  automation_account_name = local.automation_account_name
  frequency               = "Hour"
  interval                = 1
  timezone                = "UTC"
  description             = "Run every hour"
  start_time              = timeadd(timestamp(), "10m")
  depends_on = [
    azurerm_resource_group_template_deployment.ARMdeploy-automation-acct
  ]
}

resource "azurerm_automation_job_schedule" "demo_sched" {
    resource_group_name     = var.resource_group.name
    automation_account_name = local.automation_account_name
    schedule_name           = azurerm_automation_schedule.hourly.name
    runbook_name            = azurerm_automation_runbook.demo_rb.name
    depends_on              = [azurerm_automation_schedule.hourly]
}