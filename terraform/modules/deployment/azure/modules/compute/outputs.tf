output "ssh_key_path" { 
    value = local.ssh_key_path 
}

output "instances" { 
    sensitive = false
    value = local.instances
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