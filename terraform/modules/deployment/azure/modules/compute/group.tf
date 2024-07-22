# compute admin group
resource "azuread_group" "compute-admin-group-app" {
  display_name = "compute-${var.environment}-${var.deployment}-admins"
  owners = [data.azurerm_client_config.current.object_id]
  security_enabled = true
}

# add current user to the compute admin group
resource "azuread_group_member" "compute-admin-members" {
  group_object_id = azuread_group.compute-admin-group.id
  member_object_id = data.azurerm_client_config.current.object_id
}

# add a role to the group allowing member login to virtual machine (allows aadloginforlinux access)
resource "azurerm_role_assignment" "virtual-machine-login-perms" {
  for_each           = { for instance in var.instances: instance.name => instance if instance.role == "default" }
  scope              = azurerm_linux_virtual_machine.instances[each.key].id
  role_definition_id = "Virtual Machine User Login"
  principal_id       = azuread_group.compute-admin-group.object_id
}

# do the same for the app instances
resource "azurerm_role_assignment" "virtual-machine-login-app-perms" {
  for_each           = { for instance in var.instances: instance.name => instance if instance.role == "app" }
  scope              = azurerm_linux_virtual_machine.instances-app[each.key].id
  role_definition_id = "Virtual Machine User Login"
  principal_id       = azuread_group.compute-admin-group.object_id
}