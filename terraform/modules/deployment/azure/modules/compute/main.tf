####################################################
# COMPUTE NETWORK
####################################################

resource "azurerm_virtual_network" "network" {
    name                = "public-vnet-${var.environment}-${var.deployment}"
    address_space       = [var.public_network]
    location            = var.region
    resource_group_name = var.resource_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "true"
        role        = "default"
    }
}

resource "azurerm_subnet" "subnet" {
    name                 = "public-subnet-${var.environment}-${var.deployment}"
    resource_group_name  = var.resource_group.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes       = [var.public_subnet]
}

resource "azurerm_subnet" "subnet-private" {
    # name                 = "private-subnet-${var.environment}-${var.deployment}"
    name                 = "GatewaySubnet"
    resource_group_name  = var.resource_group.name
    virtual_network_name = azurerm_virtual_network.network-private.name
    address_prefixes       = [var.private_subnet]
}

resource "azurerm_virtual_network" "network-private" {
    name                = "private-vnet-${var.environment}-${var.deployment}"
    address_space       = [var.private_network]
    location            = var.region
    resource_group_name = var.resource_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "false"
        role        = "default"
    }
}

resource "azurerm_public_ip" "private-nat-gw" {
    name                  = "private-ip-${var.environment}-${var.deployment}"
    location              = var.region
    resource_group_name   = var.resource_group.name
    allocation_method     = "Dynamic"

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "false"
        role        = "default"
    }
}

resource "azurerm_virtual_network_gateway" "private-nat-gw" {
    name                = "private-natgw-${var.environment}-${var.deployment}"
    location            = var.region
    resource_group_name = var.resource_group.name

    type     = "Vpn"
    vpn_type = "RouteBased"
    sku      = "Basic"

    ip_configuration {
        public_ip_address_id          = azurerm_public_ip.private-nat-gw.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = azurerm_subnet.subnet-private.id
    }

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "true"
        role        = "default"
    }
}

resource "azurerm_public_ip" "ip" {
    for_each                     = { for instance in var.instances: instance.name => instance if instance.public == true  && instance.role == "default" }
    name                         = "ip-${ each.key }-${var.environment}-${var.deployment}"
    location                     = var.region
    resource_group_name          = var.resource_group.name
    allocation_method            = "Dynamic"

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "true"
        role        = "default"
    }
}

resource "azurerm_network_security_group" "sg" {
    name                = "public-sg-${var.environment}-${var.deployment}"
    location            = var.region
    resource_group_name = var.resource_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "true"
        role        = "default"
    }
}

resource "azurerm_network_security_rule" "public-ingress-rules" {
  count                       = length(var.public_ingress_rules)
  name                        = "public-sg-ingress-${var.environment}-${var.deployment}-${count.index}"
  priority                    = 1000+count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = var.public_ingress_rules[count.index].protocol == "tcp" ? "Tcp" : "Udp"
  source_port_range           = "*"
  destination_port_range      = "${var.public_ingress_rules[count.index].from_port}-${var.public_ingress_rules[count.index].to_port}"
  source_address_prefix       = "${var.public_ingress_rules[count.index].cidr_block}"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.sg.name
}

resource "azurerm_network_security_group" "sg-private" {
    name                = "private-sg-${var.environment}-${var.deployment}"
    location            = var.region
    resource_group_name = var.resource_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        public      = "false"
        role        = "default"
    }
}

resource "azurerm_network_security_rule" "private-ingress-rules" {
  count                       = length(var.private_ingress_rules)
  name                        = "private-sg-ingress-${var.environment}-${var.deployment}-${count.index}"
  priority                    = 1000+count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = var.private_ingress_rules[count.index] == "tcp" ? "Tcp" : "Udp"
  source_port_range           = "*"
  destination_port_range      = "${var.private_ingress_rules[count.index].from_port}-${var.private_ingress_rules[count.index].to_port}"
  source_address_prefix       = "${var.private_ingress_rules[count.index].cidr_block}"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.sg-private.name
}

resource "azurerm_network_interface" "nic" {
    for_each                    = { for instance in var.instances: instance.name => instance if instance.role == "default" }
    name                        = "nic-${ each.key }-${var.environment}-${var.deployment}"
    location                    = var.region
    resource_group_name         = var.resource_group.name

    ip_configuration {
        name                          = "nic-config-${each.key}-${var.environment}-${var.deployment}"
        subnet_id                     = each.value.public == true ? azurerm_subnet.subnet.id : azurerm_subnet.subnet-private.id 
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = each.value.public == true ? azurerm_public_ip.ip[each.key].id : null
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
resource "azurerm_network_interface_security_group_association" "sg" {
    for_each                    = { for instance in var.instances: instance.name => instance if instance.role == "default" }
    network_interface_id        = azurerm_network_interface.nic[each.key].id
    network_security_group_id   = each.value.public == true ? azurerm_network_security_group.sg.id : azurerm_network_security_group.sg-private.id
}

# Assign system user assigned identity reader access to the resource group
resource "azurerm_user_assigned_identity" "instance-user-identity" {
    name                  = "instance-user-identity-${var.environment}-${var.deployment}"
    location              = var.region
    resource_group_name   = var.resource_group.name

    tags = {
        environment = var.environment
        deployment  = var.deployment
        role = "default"
    }
}

resource "azurerm_role_assignment" "instance-user-idenity-role-assignment" {
    principal_id          = azurerm_user_assigned_identity.instance-user-identity.principal_id
    role_definition_name  = "Reader"
    scope                 = var.resource_group.id
}

# Custom role for system identity allowing read access to the user assigned identity
resource "azurerm_role_definition" "system-role-definition" {
    name                  = "system-role-${var.environment}-${var.deployment}"
    scope                 = var.resource_group.id
    description           = "Custom role to read specific user-assigned identities"

    permissions {
        actions = [
            "Microsoft.ManagedIdentity/userAssignedIdentities/read"
        ]
        not_actions = []
    }

    assignable_scopes = [
        azurerm_user_assigned_identity.instance-user-identity.id
    ]
}

# Allow the system assigned identity reader access to the user assigned identity for the purposes of assuming the privilege user identity
resource "azurerm_role_assignment" "system-identity-role" {
    for_each              = { for instance in var.instances: instance.name => instance if instance.role == "default" }
    principal_id          = azurerm_linux_virtual_machine.instances[each.key].identity[0].principal_id
    role_definition_name  = azurerm_role_definition.system-role-definition.name
    scope                 = data.azurerm_subscription.current.id

    depends_on = [
        azurerm_linux_virtual_machine.instances,
        azurerm_role_definition.system-role-definition,
        azurerm_user_assigned_identity.instance-user-identity
    ]
}

####################################################
# COMPUTE INSTANCES
####################################################

# Create the linux virtual machine
resource "azurerm_linux_virtual_machine" "instances" {
    for_each              = { for instance in var.instances: instance.name => instance if instance.role == "default" }
    name                  = "${each.key}-${var.environment}-${var.deployment}"
    location              = var.region
    resource_group_name   = var.resource_group.name
    network_interface_ids = [azurerm_network_interface.nic[each.key].id]
    size                  = each.value.instance_type

    identity {
        type         = "SystemAssigned, UserAssigned"
        identity_ids = [azurerm_user_assigned_identity.instance-user-identity.id]
    }

    os_disk {
        name              = "disk-${each.key}-${var.environment}-${var.deployment}"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = local.amis[each.value.ami_name].publisher
        offer     = local.amis[each.value.ami_name].offer
        sku       = local.amis[each.value.ami_name].sku
        version   = local.amis[each.value.ami_name].version
    }

    computer_name  = "${each.key}-${var.environment}-${var.deployment}"
    admin_username = var.admin_user
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = var.admin_user
        public_key     = tls_private_key.ssh.public_key_openssh
    }


    tags = merge({"environment"=var.environment},{"deployment"=var.deployment},{"public"="${each.value.public == true ? "true" : "false"}"},{"access-role"=azurerm_user_assigned_identity.instance-user-identity.name},each.value.tags)
}