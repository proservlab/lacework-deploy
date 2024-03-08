locals {
    # ssh_key_path_app = pathexpand("~/.ssh/azure-app-${var.environment}-${var.deployment}.pem")
    resource_group_name_app = var.resource_app_group.name
}

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

resource "azurerm_subnet" "subnet-app-private" {
    name                 = "private-app-subnet-${var.environment}-${var.deployment}"
    resource_group_name  = var.resource_app_group.name
    virtual_network_name = azurerm_virtual_network.network-app-private.name
    address_prefixes       = [var.private_app_subnet]
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

resource "azurerm_network_security_rule" "public_ingress_rules_app" {
  count                       = length(var.public_app_ingress_rules)
  name                        = "public-app-sg-ingress-${var.environment}-${var.deployment}-${count.index}"
  priority                    = 1000+count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = var.public_app_ingress_rules[count.index] == "tcp" ? "Tcp" : "Udp"
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

resource "azurerm_network_security_rule" "private_ingress_rules_app" {
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

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sg-app" {
    for_each                    = { for instance in var.instances: instance.name => instance if instance.role == "app" }
    network_interface_id        = azurerm_network_interface.nic-app[each.key].id
    network_security_group_id   = each.value.public == true ? azurerm_network_security_group.sg-app.id : azurerm_network_security_group.sg-app-private.id
}

resource "random_id" "randomIdApp" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = var.resource_app_group.name
    }
    
    byte_length = 8
}

# use the common default ssh key
# resource "tls_private_key" "ssh-app" {
#   algorithm = "RSA"
#   rsa_bits = 4096
# }


resource "azurerm_linux_virtual_machine" "instances-app" {
    for_each              = { for instance in var.instances: instance.name => instance if instance.role == "app" }
    name                  = "${each.key}-app-${var.environment}-${var.deployment}"
    location              = var.region
    resource_group_name   = var.resource_app_group.name
    network_interface_ids = [azurerm_network_interface.nic-app[each.key].id]
    size                  = each.value.instance_type

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


    tags = merge({"environment"=var.environment},{"deployment"=var.deployment},{ "public"="${each.value.public == true ? "true" : "false"}"},each.value.tags)
}

resource "azurerm_virtual_machine_extension" "jit-vm-access-app" {
    for_each              = { for instance in var.instances: instance.name => instance if instance.role == "app" }
    name = "${each.key}-${var.environment}-${var.deployment}-jit-vm-access"
    virtual_machine_id = azurerm_linux_virtual_machine.instances-app[each.key].id
    publisher = "Microsoft.Azure.Security"
    type = "JitNetworkAccess"
    type_handler_version = "2.0"
    auto_upgrade_minor_version = true
    settings = jsonencode({
        "durationInSeconds" = 3600
    })

    depends_on = [ azurerm_linux_virtual_machine.instances-app ]

    tags = merge({"environment"=var.environment},{"deployment"=var.deployment},{ "public"="${each.value.public == true ? "true" : "false"}"},each.value.tags)
}

# use the common default ssh key
# resource "local_file" "ssh-key-app" {
#     content  = tls_private_key.ssh-app.private_key_pem
#     filename = local.ssh_key_path_app
#     file_permission = "0600"
# }