locals {
    ssh_key_path = pathexpand("~/.ssh/azure-${var.environment}-${var.deployment}.pem")
    resource_group_name = var.resource_group.name
}

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

resource "azurerm_subnet" "subnet-private" {
    name                 = "private-subnet-${var.environment}-${var.deployment}"
    resource_group_name  = var.resource_group.name
    virtual_network_name = azurerm_virtual_network.network-private.name
    address_prefixes       = [var.private_subnet]
}

resource "azurerm_public_ip" "ip" {
    for_each                     = { for instance in var.instances: instance.name => instance if instance.public == true && instance.role == "default"  }
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

resource "azurerm_network_security_rule" "public_ingress_rules" {
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

resource "azurerm_network_security_rule" "private_ingress_rules" {
  count                       = length(var.private_ingress_rules)
  name                        = "private-sg-ingress-${var.environment}-${var.deployment}-${count.index}"
  priority                    = 1000+count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = var.private_ingress_rules[count.index].protocol == "tcp" ? "Tcp" : "Udp"
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

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sg" {
    for_each                    = { for instance in var.instances: instance.name => instance if instance.role == "default" }
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
    for_each              = { for instance in var.instances: instance.name => instance if instance.role == "default" }
    name                  = "${each.key}-${var.environment}-${var.deployment}"
    location              = var.region
    resource_group_name   = var.resource_group.name
    network_interface_ids = [azurerm_network_interface.nic[each.key].id]
    size                  = each.value.instance_type

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


    tags = merge({"environment"=var.environment},{"deployment"=var.deployment},{ "public"="${each.value.public == true ? "true" : "false"}"},each.value.tags)
}

resource "azurerm_virtual_machine_extension" "jit-vm-access" {
    for_each              = { for instance in var.instances: instance.name => instance if instance.role == "app" }
    name = "${each.key}-${var.environment}-${var.deployment}-jit-vm-access"
    virtual_machine_id = azurerm_linux_virtual_machine.instances[each.key].id
    publisher = "Microsoft.Azure.Security"
    type = "JitNetworkAccess"
    type_handler_version = "1.4"
    auto_upgrade_minor_version = true
    settings = jsonencode({
        "durationInSeconds" = 3600
    })

    depends_on = [ azurerm_linux_virtual_machine.instances ]

    tags = merge({"environment"=var.environment},{"deployment"=var.deployment},{ "public"="${each.value.public == true ? "true" : "false"}"},each.value.tags)
}

resource "local_file" "ssh-key" {
    content  = tls_private_key.ssh.private_key_pem
    filename = local.ssh_key_path
    file_permission = "0600"
}

locals {
    instances = flatten([
            [for instance in azurerm_linux_virtual_machine.instances : {
                name       = instance.name
                public_ip  = instance.public_ip_address
                admin_user = instance.admin_username
                role       = lookup(instance.tags,"role","default")
                public     = lookup(instance.tags,"public","false")
                tags       = instance.tags
            }],
            [for instance in azurerm_linux_virtual_machine.instances-app : {
                name       = instance.name
                public_ip  = instance.public_ip_address
                admin_user = instance.admin_username
                role       = lookup(instance.tags,"role","app")
                public     = lookup(instance.tags,"public","false")
                tags       = instance.tags
            }]
    ])

    public_compute_instances = var.enable_dynu_dns == true ? [ for compute in local.instances: compute.public_ip if compute.public == "true" ] : []
    public_instances = [ for compute in local.instances: compute.public_ip if compute.role == "default" && compute.public == "true" ]
    public_app_instances = [ for compute in local.instances: compute.public_ip if compute.role == "app" && compute.public == "true" ]
    private_instances = [ for compute in local.instances: compute.public_ip if compute.role == "default" && compute.public == "false" ]
    private_app_instances = [ for compute in local.instances: compute.public_ip if compute.role == "app" && compute.public == "false" ]
}


module "dns-records" {
    for_each              = { for instance in local.public_compute_instances: instance.name => instance }
    source              = "../../../common/dynu-dns-record"
    dynu_api_key        = var.dynu_api_key
    dynu_dns_domain     = var.dynu_dns_domain
    
    record        = {
            recordType     = "A"
            recordName     = "${each.key}"
            recordHostName = "${each.key}.${coalesce(var.dynu_dns_domain, "unknown")}"
            recordValue    = each.value.public_ip
        }
    
    depends_on = [
        azurerm_linux_virtual_machine.instances,
        azurerm_linux_virtual_machine.instances-app 
    ]
}

