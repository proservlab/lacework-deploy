locals {
    server_name                     = "${var.server_name}-${var.environment}-${var.deployment}"
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "azuread_service_principal" "this" {
  count = try(length(var.service_principal_display_name), "false") != "false" ? 1 : 0
  display_name = var.service_principal_display_name
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


resource "azurerm_key_vault" "this" {
  name                        = "db-vault-${var.environment}-${var.deployment}"
  location                    = var.region
  resource_group_name         = var.db_resource_group_name
  tenant_id                   = data.azurerm_subscription.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

# ensure current user is able to access modify after creation
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${data.azurerm_client_config.current.object_id}"

  key_permissions = [
    "Get",
	  "List",
	  "Create",
  ]

  secret_permissions = [
    "Get",
	  "List",
	  "Set",
  ]
}

resource "azurerm_key_vault_access_policy" "this" {
  count = try(length(var.service_principal_display_name), "false") != "false" ? 1 : 0
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_subscription.current.tenant_id
  object_id    = data.azuread_service_principal.this[0].id

  key_permissions = [
    "Get",
	  "List",
  ]

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_key_vault_secret" "db_host" {
  name         = "db-host"
  value        = var.instance_type == "mysql" ? azurerm_mysql_flexible_server.this[0].fqdn : azurerm_postgresql_flexible_server.this[0].fqdn
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [ 
    azurerm_key_vault.this,
    azurerm_key_vault_access_policy.this,
    azurerm_key_vault_access_policy.current
  ]
}

resource "azurerm_key_vault_secret" "db_port" {
  name         = "db-port"
  value        = var.instance_type == "mysql" ? 3306 : 5432
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [ 
    azurerm_key_vault.this,
    azurerm_key_vault_access_policy.this,
    azurerm_key_vault_access_policy.current
  ]
}

resource "azurerm_key_vault_secret" "db_name" {
  name         = "db-name"
  value        = var.db_name
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [ 
    azurerm_key_vault.this,
    azurerm_key_vault_access_policy.this,
    azurerm_key_vault_access_policy.current
  ]
}

resource "azurerm_key_vault_secret" "db_username" {
  name         = "db-username"
  value        = var.root_db_username
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [ 
    azurerm_key_vault.this,
    azurerm_key_vault_access_policy.this,
    azurerm_key_vault_access_policy.current
  ]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_string.root_db_password.result
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [ 
    azurerm_key_vault.this,
    azurerm_key_vault_access_policy.this,
    azurerm_key_vault_access_policy.current
  ]
}

resource "azurerm_key_vault_secret" "db_region" {
  name         = "db-region"
  value        = var.region
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [ 
    azurerm_key_vault.this,
    azurerm_key_vault_access_policy.this,
    azurerm_key_vault_access_policy.current
  ]
}

resource "azurerm_subnet" "this" {
  name                              = "internal-sql-${var.environment}-${var.deployment}"
  resource_group_name               = var.db_resource_group_name
  virtual_network_name              = var.db_virtual_network_name
  address_prefixes                  = var.db_subnet_network

  service_endpoints                 = ["Microsoft.Storage"]
  
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

#######################################
# MYSQL
#######################################

# resource "azurerm_mysql_server" "this" {
#   count                             = var.instance_type == "mysql" ? 1 : 0
  # name                              = local.server_name
  # location                          = var.region
  # resource_group_name               = var.db_resource_group_name

#   sku_name                          = var.sku_name

#   storage_mb                        = 5120
#   backup_retention_days             = 7
#   auto_grow_enabled                 = true
#   geo_redundant_backup_enabled      = false
#   infrastructure_encryption_enabled = false

#   administrator_login               = var.root_db_username
#   administrator_login_password      = random_string.root_db_password.result

#   version = "5.7"

#   ssl_enforcement_enabled           = true
#   ssl_minimal_tls_version_enforced  = "TLS1_2"
#   public_network_access_enabled     = var.public_network_access_enabled
  
#   tags = {
#     environment = var.environment
#     deployment = var.deployment
#   }
# }

resource "azurerm_mysql_flexible_server" "this" {
  count                             = var.instance_type == "mysql" ? 1 : 0
  name                              = local.server_name
  location                          = var.region
  resource_group_name               = var.db_resource_group_name
  administrator_login               = var.root_db_username
  administrator_password            = random_string.root_db_password.result
  backup_retention_days             = 7
  delegated_subnet_id               = azurerm_subnet.this.id
  private_dns_zone_id               = azurerm_private_dns_zone.mysql[0].id
  # az mysql server list-skus --location westus -o table --subscription="xxxxx"
  sku_name                          = var.sku_name # "GP_Standard_D2ds_v4"

  tags = {
    environment = var.environment
    deployment = var.deployment
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]
}

# resource "azurerm_mysql_database" "this" {
#   count                             = var.instance_type == "mysql" ? 1 : 0
#   name                              = var.db_name
#   resource_group_name               = var.db_resource_group_name
#   server_name                       = azurerm_mysql_flexible_server.this[0].name
#   charset                           = "utf8"
#   collation                         = "utf8_unicode_ci"

#   depends_on = [  
#     azurerm_mysql_flexible_server.this
#   ]
# }

resource "azurerm_mysql_flexible_database" "this" {
  count                             = var.instance_type == "mysql" ? 1 : 0
  name                              = var.db_name
  resource_group_name               = var.db_resource_group_name
  server_name                       = azurerm_mysql_flexible_server.this[0].name
  charset                           = "utf8"
  collation                         = "utf8_unicode_ci"

  depends_on = [  
    azurerm_mysql_flexible_server.this
  ]
}

# resource "azurerm_mysql_virtual_network_rule" "this" {
#   count                             = var.instance_type == "mysql" ? 1 : 0
#   name                              = "db-${var.environment}-${var.deployment}-vnet-rule"
#   resource_group_name               = var.db_resource_group_name
#   server_name                       = azurerm_mysql_flexible_server.this[0].name
#   subnet_id                         = azurerm_subnet.this.id

#   depends_on = [  
#     azurerm_mysql_flexible_server.this
#   ]
# }

# the endpoint will add a private ip address to your vnet
# data sources for the vnet RG
# resource "azurerm_private_endpoint" "mysql" {
#   count               = var.instance_type == "mysql" && var.public_network_access_enabled == false ? 1 : 0
#   name                = "private-endpoint-${var.environment}-${var.deployment}"
#   location            = var.region
#   resource_group_name = var.db_resource_group_name
#   subnet_id           = azurerm_subnet.this.id

#   private_dns_zone_group {
#     name                 = "private-dns-${var.environment}-${var.deployment}"
#     private_dns_zone_ids = [azurerm_private_dns_zone.mysql[0].id]
#   }

#   private_service_connection {
#     name                           = "private-connection-${var.environment}-${var.deployment}"
#     private_connection_resource_id = azurerm_mysql_flexible_server.this[0].id
#     subresource_names              = ["mysqlServer"]
#     is_manual_connection           = false
#   }

#   depends_on = [  
#     azurerm_mysql_flexible_server.this
#   ]
# }

resource "azurerm_private_dns_zone" "mysql" {
  count               = var.instance_type == "mysql" && var.public_network_access_enabled == false ? 1 : 0
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


# Allow access from a specific IP range
# resource "azurerm_mysql_firewall_rule" "this" {
#   for_each = { for i in var.mysql_authorized_ip_ranges: "${i.start_ip_address}-${i.end_ip_address}" => i }
#   name                = "${azurerm_mysql_flexible_server.this[0].name}-rule"
#   resource_group_name = azurerm_mysql_flexible_server.this[0].resource_group_name
#   server_name         = azurerm_mysql_flexible_server.this[0].name
#   start_ip_address    = each.value.start_ip_address
#   end_ip_address      = each.value.end_ip_address
# }

# resource "azurerm_mysql_firewall_rule" "allow_azure_services" {
#   count                             = var.instance_type == "mysql" ? 1 : 0
#   name                              = "allow-azure-services"
#   resource_group_name               = azurerm_mysql_flexible_server.this[0].resource_group_name
#   server_name                       = azurerm_mysql_flexible_server.this[0].name
#   start_ip_address                  = "0.0.0.0"
#   end_ip_address                    = "0.0.0.0"
  
#   depends_on = [  
#     azurerm_mysql_flexible_server.this
#   ]
# }

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
  count                             = var.instance_type == "mysql" ? 1 : 0
  name                              = "allow-azure-services"
  resource_group_name               = azurerm_mysql_flexible_server.this[0].resource_group_name
  server_name                       = azurerm_mysql_flexible_server.this[0].name
  start_ip_address                  = "0.0.0.0"
  end_ip_address                    = "0.0.0.0"
  
  depends_on = [  
    azurerm_mysql_flexible_server.this
  ]
}



#######################################
# POSTGRES
#######################################

# resource "azurerm_postgresql_server" "this" {
#   count                             = var.instance_type == "postgres" ? 1 : 0
#   name                              = local.server_name
#   location                          = var.region
#   resource_group_name               = var.db_resource_group_name

#   sku_name                          = var.sku_name

#   storage_mb                        = 5120
#   backup_retention_days             = 7
#   auto_grow_enabled                 = true
#   geo_redundant_backup_enabled      = false
#   infrastructure_encryption_enabled = false

#   administrator_login               = var.root_db_username
#   administrator_login_password      = random_string.root_db_password.result

#   version                           = "9.5"
#   ssl_enforcement_enabled           = true
#   public_network_access_enabled     = var.public_network_access_enabled

#   tags = {
#     environment = var.environment
#     deployment = var.deployment
#   }
# }

resource "azurerm_postgresql_flexible_server" "this" {
  count                             = var.instance_type == "postgres" ? 1 : 0
  name                              = local.server_name
  location                          = var.region
  resource_group_name               = var.db_resource_group_name
  administrator_login               = var.root_db_username
  administrator_password            = random_string.root_db_password.result
  backup_retention_days             = 7
  delegated_subnet_id               = azurerm_subnet.this.id
  private_dns_zone_id               = azurerm_private_dns_zone.postgres[0].id
  # az postgres server list-skus --location westus -o table --subscription="xxxxx"
  sku_name                          = var.sku_name # "GP_Standard_D2ds_v4"

  tags = {
    environment = var.environment
    deployment = var.deployment
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# resource "azurerm_postgresql_database" "this" {
#   count                             = var.instance_type == "postgres" ? 1 : 0
#   name                              = var.db_name
#   resource_group_name               = var.db_resource_group_name
#   server_name                       = azurerm_postgresql_flexible_server.this[0].name
#   charset                           = "UTF8"
#   collation                         = "English_United States.1252"

#   depends_on = [  
#     azurerm_postgresql_flexible_server.this
#   ]
# }

resource "azurerm_postgresql_flexible_server_database" "this" {
  count                             = var.instance_type == "postgres" ? 1 : 0
  name                              = var.db_name
  server_id                         = azurerm_postgresql_flexible_server.this[0].id
  charset                           = "utf8"
  collation                         = "en_US.utf8"

  depends_on = [  
    azurerm_postgresql_flexible_server.this
  ]
}

# resource "azurerm_postgresql_virtual_network_rule" "this" {
#   count                                = var.instance_type == "postgres" && var.public_network_access_enabled == true ? 1 : 0
#   name                                 = "db-${var.environment}-${var.deployment}-vnet-rule"
#   resource_group_name                  = var.db_resource_group_name
#   server_name                          = azurerm_postgresql_flexible_server.this[0].name
#   subnet_id                            = azurerm_subnet.this.id
#   ignore_missing_vnet_service_endpoint = true

#   depends_on = [  
#     azurerm_postgresql_flexible_server.this
#   ]
# }

# the endpoint will add a private ip address to your vnet
# data sources for the vnet RG
# resource "azurerm_private_endpoint" "postgres" {
#   count                                = var.instance_type == "postgres" && var.public_network_access_enabled == false ? 1 : 0
#   name                = "private-endpoint-${var.environment}-${var.deployment}"
#   location            = var.region
#   resource_group_name = var.db_resource_group_name
#   subnet_id           = azurerm_subnet.this.id

#   private_dns_zone_group {
#     name                 = "private-dns-${var.environment}-${var.deployment}"
#     private_dns_zone_ids = [azurerm_private_dns_zone.postgres[0].id]
#   }

#   private_service_connection {
#     name                           = "private-connection-${var.environment}-${var.deployment}"
#     private_connection_resource_id = azurerm_postgresql_flexible_server.this[0].id
#     subresource_names              = ["postgresqlServer"]
#     is_manual_connection           = false
#   }

#   depends_on = [  
#     azurerm_postgresql_flexible_server.this
#   ]
# }

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

# Allow access from a specific IP range
# resource "azurerm_postgresql_firewall_rule" "this" {
#   for_each = { for i in var.postgres_authorized_ip_ranges: "${i.start_ip_address}-${i.end_ip_address}" => i }
#   name                = "${azurerm_postgresql_flexible_server.this[0].name}-rule"
#   resource_group_name = azurerm_postgresql_flexible_server.this[0].resource_group_name
#   server_name         = azurerm_postgresql_flexible_server.this[0].name
#   start_ip_address    = each.value.start_ip_address
#   end_ip_address      = each.value.end_ip_address
# }

# resource "azurerm_postgresql_firewall_rule" "allow_azure_services" {
#   count                             = var.instance_type == "postgres" ? 1 : 0
#   name                              = "allow-azure-services"
#   resource_group_name               = azurerm_postgresql_flexible_server.this[0].resource_group_name
#   server_name                       = azurerm_postgresql_flexible_server.this[0].name
#   start_ip_address                  = "0.0.0.0"
#   end_ip_address                    = "0.0.0.0"

#   depends_on = [  
#     azurerm_postgresql_flexible_server.this
#   ]
# }

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  count                             = var.instance_type == "postgres" ? 1 : 0
  name                              = "allow-azure-services"
  server_id                       = azurerm_postgresql_flexible_server.this[0].name
  start_ip_address                  = "0.0.0.0"
  end_ip_address                    = "0.0.0.0"

  depends_on = [  
    azurerm_postgresql_flexible_server.this
  ]
}
