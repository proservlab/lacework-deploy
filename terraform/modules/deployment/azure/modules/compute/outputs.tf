output "ssh_key_path" { 
    value = local.ssh_key_path 
}

output "instances" { 
    sensitive = false
    value = flatten([
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
}

output "resource_group" { 
    value = var.resource_group 
}

output "resource_app_group" { 
    value = var.resource_app_group 
}

output "public_virtual_network" { 
    value = azurerm_virtual_network.network 
}

output "public_security_group" { 
    value = azurerm_network_security_group.sg 
}

output "public_app_virtual_network" { 
    value = azurerm_virtual_network.network-app 
}

output "public_app_security_group" { 
    value = azurerm_network_security_group.sg-app 
}

output "private_virtual_network" { 
    value = azurerm_virtual_network.network-private 
}

output "private_security_group" { 
    value = azurerm_network_security_group.sg-private 
}

output "private_app_virtual_network" { 
    value = azurerm_virtual_network.network-app-private 
}

output "private_app_security_group" { 
    value = azurerm_network_security_group.sg-app-private 
}