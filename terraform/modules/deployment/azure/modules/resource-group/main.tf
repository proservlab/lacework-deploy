resource "azurerm_resource_group" "resource-group" {
    name     = "${var.name}-${var.environment}-${var.deployment}"
    location = var.region

    tags = {
        environment = var.environment
        deployment = var.deployment
    }
}