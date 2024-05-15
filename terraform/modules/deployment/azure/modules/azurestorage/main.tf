

resource "azurerm_subnet" "this" {
  name                 = "internal-storage-${var.environment}-${var.deployment}"
  resource_group_name  = var.storage_resource_group_name
  virtual_network_name = var.storage_virtual_network_name
  address_prefixes     = var.storage_subnet_network

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_storage_account" "this" {
  name                     = "${var.environment}${var.deployment}"
  resource_group_name      = var.storage_resource_group_name
  location                 = var.region
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  network_rules {
    default_action = "Deny"
    ip_rules       = var.public_network_access_enabled == true ? flatten(
      [
        ["0.0.0.0/0"],var.trusted_networks
      ]) : var.trusted_networks # If you want to allow the VM's private IP.
  }

  tags = {
    environment = var.environment
    deployment  = var.deployment
  }
}

resource "azurerm_private_endpoint" "this" {
  name                = "storage-endpoint-${var.environment}-${var.deployment}"
  location            = var.region
  resource_group_name = var.storage_resource_group_name
  subnet_id           = azurerm_subnet.this.id

  private_service_connection {
    name                           = "storage-service-connection-${var.environment}-${var.deployment}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "stroage-dns-group-${var.environment}-${var.deployment}"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.storage_resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "storage-link-${var.environment}-${var.deployment}"
  resource_group_name   = var.storage_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.storage_virtual_network_id
}