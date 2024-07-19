locals {
    server_name                     = "${var.server_name}-${var.environment}-${var.deployment}"
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "azuread_service_principal" "this" {
  count = var.add_service_principal_access ? 1 : 0
  display_name = var.service_principal_display_name
}

# Custom role for user managed identity allowing enumeration of sql instances
resource "azurerm_role_definition" "service-principal-sql-read-role-definition" {
    count = var.add_service_principal_access ? 1 : 0
    name                  = "service-principal-sql-read-role-${var.environment}-${var.deployment}"
    scope                 = data.azuread_service_principal.this[0].id
    description           = "Custom role to read flexible sql server list"

    permissions {
        actions = [
            var.instance_type == "mysql" ? "Microsoft.DBforMySQL/flexibleServers/read" : "Microsoft.DBforPostgreSQL/flexibleServers/read"
        ]
        not_actions = []
    }
    
    assignable_scopes = [
        # allow read access to this sql instance
        var.instance_type == "mysql" ? azurerm_mysql_flexible_server.this[0].id : azurerm_postgresql_flexible_server.this[0].id
        # allow read of all sql servers in the resource group
        # var.db_resource_group_name
    ]
}

resource "azurerm_role_assignment" "system-identity-role-app" {
    count = var.add_service_principal_access ? 1 : 0
    principal_id          = data.azuread_service_principal.this[0].id
    role_definition_name  = azurerm_role_definition.service-principal-sql-read-role-definition[0].name
    scope                 = var.instance_type == "mysql" ? azurerm_mysql_flexible_server.this[0].id : azurerm_postgresql_flexible_server.this[0].id

    depends_on = [
        azurerm_role_definition.service-principal-sql-read-role-definition,
        data.azuread_service_principal.this,
        azurerm_mysql_flexible_server.this,
        azurerm_postgresql_flexible_server.this
    ]
}

data "azurerm_user_assigned_identity" "this" {
  name                = "instance-user-identity-app-${var.environment}-${var.deployment}"
  resource_group_name = var.db_resource_group_name
}

# Custom role for user managed identity allowing enumeration of sql instances
resource "azurerm_role_definition" "user-managed-identiy-sql-read-role-definition" {
    name                  = "user-managed-identity-sql-read-role-${var.environment}-${var.deployment}"
    scope                 = data.azurerm_user_assigned_identity.this.id
    description           = "Custom role to read flexible sql server list"

    permissions {
        actions = [
            var.instance_type == "mysql" ? "Microsoft.DBforMySQL/flexibleServers/read" : "Microsoft.DBforPostgreSQL/flexibleServers/read"
        ]
        not_actions = []
    }

    assignable_scopes = [
        # allow read access to this sql instance
        var.instance_type == "mysql" ? azurerm_mysql_flexible_server.this[0].id : azurerm_postgresql_flexible_server.this[0].id
        # allow read of all sql servers in the resource group
        # var.db_resource_group_name
    ]
}

resource "azurerm_role_assignment" "user-managed-identity-role-app" {
    principal_id          = data.azurerm_user_assigned_identity.this.id
    role_definition_name  = azurerm_role_definition.user-managed-identiy-sql-read-role-definition.name
    scope                 = var.instance_type == "mysql" ? azurerm_mysql_flexible_server.this[0].id : azurerm_postgresql_flexible_server.this[0].id

    depends_on = [
        azurerm_role_definition.user-managed-identiy-sql-read-role-definition,
        data.azurerm_user_assigned_identity.this,
        azurerm_mysql_flexible_server.this,
        azurerm_postgresql_flexible_server.this
    ]
}

resource "random_id" "uniq" {
  byte_length                       = 4
}

resource "random_password" "root_db_password" {
    length                          = 16
    special                         = false
    upper                           = true
    lower                           = true
    numeric                         = true
    min_upper                       = 1
    min_lower                       = 1
    min_numeric                     = 1
}


resource "azurerm_key_vault" "this" {
  name                        = "db-kv-${var.environment}-${var.deployment}"
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
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
  ]

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]

  storage_permissions = [
    "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
  ]

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]
}

# grant service principal managed identity access to the key vault
resource "azurerm_key_vault_access_policy" "this" {
  count = var.add_service_principal_access ? 1 : 0
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_subscription.current.tenant_id
  object_id    = data.azuread_service_principal.this[0].id

  key_permissions = [
    "Get",
	  "List",
    "Decrypt"
  ]

  secret_permissions = [
    "Get",
    "List",
  ]
}

# grant user managed identity access to the key vault
resource "azurerm_key_vault_access_policy" "user-managed-identity" {
  count = var.add_service_principal_access ? 1 : 0
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_subscription.current.tenant_id
  object_id    = data.azurerm_user_assigned_identity.this.id

  key_permissions = [
    "Get",
	  "List",
    "Decrypt"
  ]

  secret_permissions = [
    "Get",
    "List",
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
  value        = random_password.root_db_password.result
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

resource "azurerm_mysql_flexible_server" "this" {
  count                             = var.instance_type == "mysql" ? 1 : 0
  name                              = local.server_name
  location                          = var.region
  resource_group_name               = var.db_resource_group_name
  administrator_login               = var.root_db_username
  administrator_password            = random_password.root_db_password.result
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

resource "azurerm_postgresql_flexible_server" "this" {
  count                             = var.instance_type == "postgres" ? 1 : 0
  name                              = local.server_name
  location                          = var.region
  resource_group_name               = var.db_resource_group_name
  administrator_login               = var.root_db_username
  administrator_password            = random_password.root_db_password.result
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
