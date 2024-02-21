locals {
    server_name                     = "${var.server_name}-${var.environment}-${var.deployment}"
}

resource "random_id" "uniq" {
  byte_length                       = 4
}

resource "random_string" "root_db_password" {
    length                          = 16
    special                         = false
    upper                           = true
    lower                           = true
    numeric                         = true
}

resource "azurerm_subnet" "this" {
  name                              = "internal-sql-${var.environment}-${var.deployment}"
  resource_group_name               = var.db_resource_group_name
  virtual_network_name              = var.db_virtual_network_name
  address_prefixes                  = var.db_subnet_network

  service_endpoints                 = ["Microsoft.Sql"]
}

#######################################
# MYSQL
#######################################

resource "azurerm_mysql_server" "this" {
  count                             = var.instance_type == "mysql" ? 1 : 0
  name                              = local.server_name
  location                          = var.region
  resource_group_name               = var.db_resource_group_name

  sku_name                          = var.sku_name

  storage_mb                        = 5120
  backup_retention_days             = 7
  auto_grow_enabled                 = true
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false

  administrator_login               = var.root_db_username
  administrator_login_password      = random_string.root_db_password.result

  version = "5.7"

  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
  public_network_access_enabled     = var.public_network_access_enabled

  tags = {
    environment = var.environment
    deployment = var.deployment
  }
}

resource "azurerm_mysql_database" "this" {
  count                             = var.instance_type == "mysql" ? 1 : 0
  name                              = var.db_name
  resource_group_name               = var.db_resource_group_name
  server_name                       = azurerm_mysql_server.this[0].name
  charset                           = "utf8"
  collation                         = "utf8_unicode_ci"
}

resource "azurerm_mysql_virtual_network_rule" "this" {
  count                             = var.instance_type == "mysql" ? 1 : 0
  name                              = "db-${var.environment}-${var.deployment}-vnet-rule"
  resource_group_name               = var.db_resource_group_name
  server_name                       = azurerm_mysql_server.this[0].name
  subnet_id                         = azurerm_subnet.this.id
}

# the endpoint will add a private ip address to your vnet
# data sources for the vnet RG
resource "azurerm_private_endpoint" "mysql" {
  count                                = var.instance_type == "mysql" && var.public_network_access_enabled == false ? 1 : 0
  name                = "private-endpoint-${var.environment}-${var.deployment}"
  location            = var.region
  resource_group_name = var.db_resource_group_name
  subnet_id           = azurerm_subnet.this.id

  private_dns_zone_group {
    name                 = "private-dns-${var.environment}-${var.deployment}"
    private_dns_zone_ids = [azurerm_private_dns_zone.mysql[0].id]
  }

  private_service_connection {
    name                           = "private-connection-${var.environment}-${var.deployment}"
    private_connection_resource_id = azurerm_mysql_server.this[0].id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_zone" "mysql" {
  count                                = var.instance_type == "mysql" && var.public_network_access_enabled == false ? 1 : 0
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.db_resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  count                                = var.instance_type == "mysql" && var.public_network_access_enabled == false ? 1 : 0
  name                  = "dns-zone-link-${var.environment}-${var.deployment}"
  resource_group_name   = var.db_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = var.db_virtual_network_id
}


#######################################
# POSTGRES
#######################################

resource "azurerm_postgresql_server" "this" {
  count                             = var.instance_type == "postgres" ? 1 : 0
  name                              = local.server_name
  location                          = var.region
  resource_group_name               = var.db_resource_group_name

  sku_name                          = var.sku_name

  storage_mb                        = 5120
  backup_retention_days             = 7
  auto_grow_enabled                 = true
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false

  administrator_login               = var.root_db_username
  administrator_login_password      = random_string.root_db_password.result

  version                           = "9.5"
  ssl_enforcement_enabled           = true
  public_network_access_enabled     = var.public_network_access_enabled

  tags = {
    environment = var.environment
    deployment = var.deployment
  }
}

resource "azurerm_postgresql_database" "this" {
  count                             = var.instance_type == "postgres" ? 1 : 0
  name                              = var.db_name
  resource_group_name               = var.db_resource_group_name
  server_name                       = azurerm_postgresql_server.this[0].name
  charset                           = "UTF8"
  collation                         = "English_United States.1252"
}

resource "azurerm_postgresql_virtual_network_rule" "this" {
  count                                = var.instance_type == "postgres" && var.public_network_access_enabled == true ? 1 : 0
  name                                 = "db-${var.environment}-${var.deployment}-vnet-rule"
  resource_group_name                  = var.db_resource_group_name
  server_name                          = azurerm_postgresql_server.this[0].name
  subnet_id                            = azurerm_subnet.this.id
  ignore_missing_vnet_service_endpoint = true
}

# the endpoint will add a private ip address to your vnet
# data sources for the vnet RG
resource "azurerm_private_endpoint" "postgres" {
  count                                = var.instance_type == "postgres" && var.public_network_access_enabled == false ? 1 : 0
  name                = "private-endpoint-${var.environment}-${var.deployment}"
  location            = var.region
  resource_group_name = var.db_resource_group_name
  subnet_id           = azurerm_subnet.this.id

  private_dns_zone_group {
    name                 = "private-dns-${var.environment}-${var.deployment}"
    private_dns_zone_ids = [azurerm_private_dns_zone.postgres[0].id]
  }

  private_service_connection {
    name                           = "private-connection-${var.environment}-${var.deployment}"
    private_connection_resource_id = azurerm_postgresql_server.this[0].id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_zone" "postgres" {
  count                                = var.instance_type == "postgres" && var.public_network_access_enabled == false ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.db_resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                                = var.instance_type == "postgres" && var.public_network_access_enabled == false ? 1 : 0
  name                  = "dns-zone-link-${var.environment}-${var.deployment}"
  resource_group_name   = var.db_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = var.db_virtual_network_id
}
