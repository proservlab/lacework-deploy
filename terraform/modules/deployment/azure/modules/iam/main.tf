locals {
        user_roles = [ for i in var.users: { for r in i.roles: "${i.name}-${r}" => {
                name = i.name
                role = r
        }} ][0]
}

data "azurerm_subscription" "current" {}

data "azuread_client_config" "current" {}

resource "azuread_application" "this" {
  for_each     = { for i in var.users : i.name => i }
  display_name = each.key
  owners       = [data.azuread_client_config.current.object_id]
}

data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "this" {
  for_each                    = { for i in var.users : i.name => i }
  client_id                    = azuread_application.this[each.key].client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "this" {
  for_each             = local.user_roles
  scope                = data.azurerm_subscription.current.id
  role_definition_name = each.value.role
  principal_id         = azuread_service_principal.this[each.value.name].id
}

resource "time_rotating" "this" {
  rotation_days = 365
}

resource "azuread_service_principal_password" "this" {
  for_each                    = { for i in var.users : i.name => i }
  service_principal_id        = azuread_service_principal.this[each.key].id
  rotate_when_changed = {
    rotation = time_rotating.this.id
  }
}