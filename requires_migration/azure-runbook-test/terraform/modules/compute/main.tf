locals {
    ssh_key_path = pathexpand("~/.ssh/azure-public.pem")
}

resource "null_resource" "trusted-local-source" {
    provisioner "local-exec" {
        command = "echo $(dig +short @resolver1.opendns.com myip.opendns.com)/32 > /tmp/local-trusted-source.txt"
    }
}

data "local_file" "trusted-source" {
    filename = "/tmp/local-trusted-source.txt"
    depends_on = [null_resource.trusted-local-source]
}


locals {
    trusted_source              = trimspace(data.local_file.trusted-source.content)
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

locals {
  custom_data = <<CUSTOM_DATA
#!/bin/bash
sudo -i 
check_apt() {
  pgrep -f "apt" || pgrep -f "dpkg"
}
while check_apt; do
  echo "Waiting for apt to be available..."
  sleep 10
done
apt-get install -y nfs-kernel-server
mkdir -p /export/a/1
mkdir -p /export/a/2
mkdir -p /export/b
cat << EOF > /etc/exports
/export/a *(rw,fsid=0,insecure,no_subtree_check,async)
/export/b *(rw,fsid=0,insecure,no_subtree_check,async)
EOF
systemctl start nfs-server
exportfs -arv
CUSTOM_DATA
}

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = var.region

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.region
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = var.environment
    }
}

resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = var.region
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = var.region
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = local.trusted_source
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "myterraformnic" {
    name                        = "myNIC"
    location                    = var.region
    resource_group_name         = azurerm_resource_group.myterraformgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = var.environment
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }
    
    byte_length = 8
}

resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}


resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = var.region
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    # current provider doesn't render a parsable image id (https://github.com/terraform-providers/terraform-provider-azurerm/issues/6745)
    #source_image_id = lower(data.azurerm_platform_image.ubuntu_image.id)

    source_image_reference {
        publisher = data.azurerm_platform_image.ubuntu_image.publisher
        offer     = data.azurerm_platform_image.ubuntu_image.offer
        sku       = data.azurerm_platform_image.ubuntu_image.sku
        version   = data.azurerm_platform_image.ubuntu_image.version
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.example_ssh.public_key_openssh
    }

    #custom_data = base64encode(local.custom_data)
    
    # boot_diagnostics {
    #     storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    # }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "local_file" "ssh-key" {
    content  = tls_private_key.example_ssh.private_key_pem
    filename = local.ssh_key_path
    file_permission = "0400"
}
