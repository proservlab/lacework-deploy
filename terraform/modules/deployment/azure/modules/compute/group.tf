data "azurerm_client_config" "current" {}

# compute admin group
resource "azuread_group" "compute-admin-group" {
  display_name = "compute-${var.environment}-${var.deployment}-admins"
  owners = [data.azurerm_client_config.current.object_id]
  security_enabled = true
}

# add current user to the compute admin group
resource "azuread_group_member" "compute-admin-members" {
  group_object_id = azuread_group.compute-admin-group.id
  member_object_id = data.azurerm_client_config.current.object_id
}

data "azurerm_role_definition" "compute-admin-role" {
  name = "Virtual Machine Administrator Login"
}

# add a role to the group allowing member login to virtual machine (allows aadloginforlinux access)
resource "azurerm_role_assignment" "virtual-machine-login-perms" {
  for_each           = { for instance in var.instances: instance.name => instance if instance.role == "default" }
  scope              = azurerm_linux_virtual_machine.instances[each.key].id
  role_definition_id = data.azurerm_role_definition.compute-admin-role.id
  principal_id       = azuread_group.compute-admin-group.object_id
  principal_type     = "Group"
  skip_service_principal_aad_check = true
}

# do the same for the app instances
resource "azurerm_role_assignment" "virtual-machine-login-app-perms" {
  for_each           = { for instance in var.instances: instance.name => instance if instance.role == "app" }
  scope              = azurerm_linux_virtual_machine.instances-app[each.key].id
  role_definition_id = data.azurerm_role_definition.compute-admin-role.id
  principal_id       = azuread_group.compute-admin-group.object_id
  principal_type     = "Group"
  skip_service_principal_aad_check = true
}