locals {
    ssh_key_path = pathexpand("~/.ssh/azure-${var.environment}-${var.deployment}.pem")
    resource_group_name = var.resource_group.name
}

module "workstation-external-ip" {
  source       = "../../../general/workstation-external-ip"
}

data "azurerm_platform_image" "ubuntu_image" {
    location  = var.region
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
}

data "azurerm_platform_image" "debian_image" {
    location  = var.region
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
}

data "azurerm_platform_image" "windowsserver_image" {
    location  = var.region
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
}

resource "azurerm_virtual_network" "network" {
    name                = "public-vnet-${var.environment}-${var.deployment}"
    address_space       = [var.public_network]
    location            = var.region
    resource_group_name = var.resource_group.name

    tags = {
        environment = var.environment
    }
}

resource "azurerm_subnet" "subnet" {
    name                 = "public-subnet-${var.environment}-${var.deployment}"
    resource_group_name  = var.resource_group.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes       = [var.public_subnet]
}

resource "azurerm_virtual_network" "network-private" {
    name                = "private-vnet-${var.environment}-${var.deployment}"
    address_space       = [var.private_network]
    location            = var.region
    resource_group_name = var.resource_group.name

    tags = {
        environment = var.environment
    }
}

resource "azurerm_subnet" "subnet-private" {
    name                 = "private-subnet-${var.environment}-${var.deployment}"
    resource_group_name  = var.resource_group.name
    virtual_network_name = azurerm_virtual_network.network-private.name
    address_prefixes       = [var.private_subnet]
}

resource "azurerm_public_ip" "ip" {
    for_each                     = { for instance in var.instances: instance.name => instance if instance.public == true  }
    name                         = "ip-${ each.key }-${var.environment}-${var.deployment}"
    location                     = var.region
    resource_group_name          = var.resource_group.name
    allocation_method            = "Dynamic"

    tags = {
        environment = var.environment
        deployment  = var.deployment
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
    }
}

resource "azurerm_network_security_rule" "public_ingress_rules" {
  count = length(var.public_ingress_rules)
  name                        = "public-sg-ingress-${var.environment}-${var.deployment}-${count.index}"
  priority                    = 1000+count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = var.public_ingress_rules[count.index] == "tcp" ? "Tcp" : "Udp"
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
    }
}

resource "azurerm_network_security_rule" "private_ingress_rules" {
  count = length(var.private_ingress_rules)
  name                        = "sg-ingress-${var.environment}-${var.deployment}-${count.index}"
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
    for_each                    = { for instance in var.instances: instance.name => instance }
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
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sg" {
    for_each                    = { for instance in var.instances: instance.name => instance }
    network_interface_id        = azurerm_network_interface.nic[each.key].id
    network_security_group_id   = each.value.public == true ? azurerm_network_security_group.sg.id : azurerm_network_security_group.sg-private.id
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = var.resource_group.name
    }
    
    byte_length = 8
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}


resource "azurerm_linux_virtual_machine" "instances" {
    for_each              = { for instance in var.instances: instance.name => instance }
    name                  = "${each.key}-${var.environment}-${var.deployment}"
    location              = var.region
    resource_group_name   = var.resource_group.name
    network_interface_ids = [azurerm_network_interface.nic[each.key].id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "disk-${each.key}-${var.environment}-${var.deployment}"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = data.azurerm_platform_image.ubuntu_image.publisher
        offer     = data.azurerm_platform_image.ubuntu_image.offer
        sku       = data.azurerm_platform_image.ubuntu_image.sku
        version   = data.azurerm_platform_image.ubuntu_image.version
    }

    computer_name  = "${each.key}-${var.environment}-${var.deployment}"
    admin_username = var.admin_user
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = var.admin_user
        public_key     = tls_private_key.ssh.public_key_openssh
    }


    tags = merge({"environment"=var.environment},{"deployment"=var.deployment},{ "public"="${each.value.public == true ? "true" : "false"}"},each.value.tags)
}

resource "local_file" "ssh-key" {
    content  = tls_private_key.ssh.private_key_pem
    filename = local.ssh_key_path
    file_permission = "0400"
}