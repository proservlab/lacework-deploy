locals {
    ssh_key_path = pathexpand("~/.ssh/azure-public.pem")
    resource_group_name = "rg-${var.environment}-${var.deployment}"
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

resource "azurerm_resource_group" "rg" {
    name     = local.resource_group_name
    location = var.region

    tags = {
        environment = var.environment
        deployment = var.deployment
    }
}

resource "azurerm_virtual_network" "network" {
    name                = "vnet-${var.environment}-${var.deployment}"
    address_space       = ["10.0.0.0/16"]
    location            = var.region
    resource_group_name = local.resource_group_name

    tags = {
        environment = var.environment
    }
}

resource "azurerm_subnet" "subnet" {
    name                 = "subnet-${var.environment}-${var.deployment}"
    resource_group_name  = local.resource_group_name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "ip" {
    name                         = "ip-${var.environment}-${var.deployment}"
    location                     = var.region
    resource_group_name          = local.resource_group_name
    allocation_method            = "Dynamic"

    tags = {
        environment = var.environment
        deployment  = var.deployment
    }
}

resource "azurerm_network_security_group" "sg" {
    name                = "sg-${var.environment}-${var.deployment}"
    location            = var.region
    resource_group_name = local.resource_group_name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = module.workstation-external-ip.cidr
        destination_address_prefix = "*"
    }

    tags = {
        environment = var.environment
        deployment  = var.deployment
    }
}

resource "azurerm_network_interface" "nic" {
    name                        = "nic-${var.environment}-${var.deployment}"
    location                    = var.region
    resource_group_name         = local.resource_group_name

    ip_configuration {
        name                          = "nic-config-${var.environment}-${var.deployment}"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.ip.id
    }

    tags = {
        environment = var.environment
        deployment  = var.deployment
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sg" {
    network_interface_id      = azurerm_network_interface.nic.id
    network_security_group_id = azurerm_network_security_group.sg.id
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = local.resource_group_name
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
    resource_group_name   = local.resource_group_name
    network_interface_ids = [azurerm_network_interface.nic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
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
    admin_username = "azureuser"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.ssh.public_key_openssh
    }


    tags = {
        environment = var.environment
        deployment = var.deployment
    }
}

resource "local_file" "ssh-key" {
    content  = tls_private_key.ssh.private_key_pem
    filename = local.ssh_key_path
    file_permission = "0400"
}