locals {
    automation_account_name = "development-automation-${var.environment}-${var.deployment}"
}

data "azurerm_subscription" "current" {
}

data "azurerm_role_definition" "vm_contributor" {
    name = "Virtual Machine Contributor"
}

resource "azurerm_role_definition" "run_command_vm" {
    name        = "RunCommandVM-${var.environment}-${var.deployment}"
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

#####################################################
# RESOURCE GROUP AUTOMATION
#####################################################

resource "azurerm_user_assigned_identity" "development_automation" {
    location            = var.resource_group.location
    resource_group_name = var.resource_group.name

    name = local.automation_account_name
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
    name                = "ARMdeploy-Automation-Start-${var.environment}-${var.deployment}"
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

    timeouts {
        create = "10m"
        delete = "30m"
    }
}

resource "azurerm_automation_module" "Azure-MI-Automation-module" {
    name                    = "Az.ManagedServiceIdentity"
    resource_group_name     = var.resource_group.name
    automation_account_name = local.automation_account_name

    module_link {
        uri = "https://www.powershellgallery.com/api/v2/package/Az.ManagedServiceIdentity/1.1.1"
    }
    depends_on = [
        azurerm_resource_group_template_deployment.ARMdeploy-automation-acct
    ]
}

resource "azurerm_automation_account" "development" {
    name                = local.automation_account_name
    location            = var.resource_group.location
    resource_group_name = var.resource_group.name
    sku_name            = "Basic"

    identity {
        type = "UserAssigned"
        identity_ids = [azurerm_user_assigned_identity.development_automation.id]
    }
}