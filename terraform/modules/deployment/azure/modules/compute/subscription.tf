data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "default" {
  name = var.resource_group_name
}

data "azurerm_resource_group" "app" {
  name = var.resource_group_name_app
}