####################################################
# COMPUTE NETWORK
####################################################

resource "azurerm_virtual_network" "network-app" {
    name                = "public-app-vnet-${var.environment}-${var.deployment}"
    address_space       = [var.public_app_network]
    location            = var.region
    resource_group_name = var.resource_app_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "true"
        role        = "app"
    }
}

resource "azurerm_subnet" "subnet-app" {
    name                 = "public-app-subnet-${var.environment}-${var.deployment}"
    resource_group_name  = var.resource_app_group.name
    virtual_network_name = azurerm_virtual_network.network-app.name
    address_prefixes       = [var.public_app_subnet]
}

resource "azurerm_subnet" "subnet-app-private" {
    # name                 = "private-app-subnet-${var.environment}-${var.deployment}"
    name                 = "GatewaySubnet"
    resource_group_name  = var.resource_app_group.name
    virtual_network_name = azurerm_virtual_network.network-app-private.name
    address_prefixes       = [var.private_app_subnet]
}

resource "azurerm_virtual_network" "network-app-private" {
    name                = "private-app-vnet-${var.environment}-${var.deployment}"
    address_space       = [var.private_app_network]
    location            = var.region
    resource_group_name = var.resource_app_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "false"
        role        = "app"
    }
}

resource "azurerm_public_ip" "private-app-nat-gw" {
    name                  = "private-app-ip-${var.environment}-${var.deployment}"
    location              = var.region
    resource_group_name   = var.resource_app_group.name
    allocation_method     = "Dynamic"

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "false"
        role        = "app"
    }
}

resource "azurerm_virtual_network_gateway" "private-app-nat-gw" {
    name                = "private-app-natgw-${var.environment}-${var.deployment}"
    location            = var.region
    resource_group_name = var.resource_app_group.name

    type     = "Vpn"
    vpn_type = "RouteBased"
    sku      = "Basic"

    ip_configuration {
        public_ip_address_id          = azurerm_public_ip.private-app-nat-gw.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = azurerm_subnet.subnet-app-private.id
    }

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "true"
        role        = "app"
    }
}

resource "azurerm_public_ip" "ip-app" {
    for_each                     = { for instance in var.instances: instance.name => instance if instance.public == true  && instance.role == "app" }
    name                         = "ip-app-${ each.key }-${var.environment}-${var.deployment}"
    location                     = var.region
    resource_group_name          = var.resource_app_group.name
    allocation_method            = "Dynamic"

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "true"
        role        = "app"
    }
}

resource "azurerm_network_security_group" "sg-app" {
    name                = "public-app-sg-${var.environment}-${var.deployment}"
    location            = var.region
    resource_group_name = var.resource_app_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "true"
        role        = "app"
    }
}

resource "azurerm_network_security_rule" "public-ingress-rules-app" {
  count                       = length(var.public_app_ingress_rules)
  name                        = "public-app-sg-ingress-${var.environment}-${var.deployment}-${count.index}"
  priority                    = 1000+count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = var.public_app_ingress_rules[count.index].protocol == "tcp" ? "Tcp" : "Udp"
  source_port_range           = "*"
  destination_port_range      = "${var.public_app_ingress_rules[count.index].from_port}-${var.public_app_ingress_rules[count.index].to_port}"
  source_address_prefix       = "${var.public_app_ingress_rules[count.index].cidr_block}"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_app_group.name
  network_security_group_name = azurerm_network_security_group.sg-app.name
}

resource "azurerm_network_security_group" "sg-app-private" {
    name                = "private-app-sg-${var.environment}-${var.deployment}"
    location            = var.region
    resource_group_name = var.resource_app_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "false"
        role        = "app"
    }
}

resource "azurerm_network_security_rule" "private-ingress-rules-app" {
  count                       = length(var.private_app_ingress_rules)
  name                        = "private-app-sg-ingress-${var.environment}-${var.deployment}-${count.index}"
  priority                    = 1000+count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = var.private_app_ingress_rules[count.index] == "tcp" ? "Tcp" : "Udp"
  source_port_range           = "*"
  destination_port_range      = "${var.private_app_ingress_rules[count.index].from_port}-${var.private_app_ingress_rules[count.index].to_port}"
  source_address_prefix       = "${var.private_app_ingress_rules[count.index].cidr_block}"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_app_group.name
  network_security_group_name = azurerm_network_security_group.sg-app-private.name
}

resource "azurerm_network_interface" "nic-app" {
    for_each                    = { for instance in var.instances: instance.name => instance if instance.role == "app" }
    name                        = "nic-app-${ each.key }-${var.environment}-${var.deployment}"
    location                    = var.region
    resource_group_name         = var.resource_app_group.name

    ip_configuration {
        name                          = "nic-app-config-${each.key}-${var.environment}-${var.deployment}"
        subnet_id                     = each.value.public == true ? azurerm_subnet.subnet-app.id : azurerm_subnet.subnet-app-private.id 
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = each.value.public == true ? azurerm_public_ip.ip-app[each.key].id : null
    }

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public = each.value.public
        role = each.value.role
    }
}

####################################################
# COMPUTE IDENTITY
####################################################

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sg-app" {
    for_each                    = { for instance in var.instances: instance.name => instance if instance.role == "app" }
    network_interface_id        = azurerm_network_interface.nic-app[each.key].id
    network_security_group_id   = each.value.public == true ? azurerm_network_security_group.sg-app.id : azurerm_network_security_group.sg-app-private.id
}

# Assign system user assigned identity reader access to the resource group
resource "azurerm_user_assigned_identity" "instance-user-identity-app" {
    name                  = "instance-user-identity-app-${var.environment}-${var.deployment}"
    location              = var.region
    resource_group_name   = var.resource_app_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        role = "app"
    }
}

resource "azurerm_role_assignment" "instance-user-idenity-role-assignment-app" {
    principal_id          = azurerm_user_assigned_identity.instance-user-identity-app.principal_id
    role_definition_name  = "Reader"
    scope                 = var.resource_app_group.id
    skip_service_principal_aad_check = true
}

# Custom role for system identity allowing read access to the user assigned identity
resource "azurerm_role_definition" "system-role-definition-app" {
  name        = "system-app-role-${var.environment}-${var.deployment}"
  scope       = var.resource_app_group.id  # Define at the resource group level
  description = "Custom role to read specific user-assigned identities"

  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    var.resource_app_group.id  # Ensure this includes the necessary scope
  ]
}

# Allow the system assigned identity reader access to the user assigned identity for the purposes of assuming the privilege user identity
resource "azurerm_role_assignment" "system-identity-role-app" {
  for_each             = { for instance in var.instances: instance.name => instance if instance.role == "app" }
  principal_id         = azurerm_linux_virtual_machine.instances-app[each.key].identity[0].principal_id
  role_definition_name = azurerm_role_definition.system-role-definition-app.name
  scope                = azurerm_user_assigned_identity.instance-user-identity-app.id  # Assign at the user-assigned identity scope
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_linux_virtual_machine.instances-app,
    azurerm_role_definition.system-role-definition-app,
    azurerm_user_assigned_identity.instance-user-identity-app
  ]
}

####################################################
# COMPUTE INSTANCES
####################################################

# Create the linux virtual machine
resource "azurerm_linux_virtual_machine" "instances-app" {
    for_each              = { for instance in var.instances: instance.name => instance if instance.role == "app" }
    name                  = "${each.key}-app-${var.environment}-${var.deployment}"
    location              = var.region
    resource_group_name   = var.resource_app_group.name
    network_interface_ids = [azurerm_network_interface.nic-app[each.key].id]
    size                  = each.value.instance_type

    identity {
        type         = "SystemAssigned, UserAssigned"
        identity_ids = [azurerm_user_assigned_identity.instance-user-identity-app.id]
    }

    os_disk {
        name              = "disk-app-${each.key}-${var.environment}-${var.deployment}"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = local.amis[each.value.ami_name].publisher
        offer     = local.amis[each.value.ami_name].offer
        sku       = local.amis[each.value.ami_name].sku
        version   = local.amis[each.value.ami_name].version
    }

    computer_name  = "${each.key}-app-${var.environment}-${var.deployment}"
    admin_username = var.admin_user
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = var.admin_user
        public_key     = tls_private_key.ssh.public_key_openssh
    }


    tags = merge({"environment"=var.environment},{"deployment"=var.deployment},{"public"="${each.value.public == true ? "true" : "false"}"},{"access-role"=azurerm_user_assigned_identity.instance-user-identity-app.name},each.value.tags)
}