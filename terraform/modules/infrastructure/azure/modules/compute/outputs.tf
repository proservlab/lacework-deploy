output "ssh_key_path" { 
    value = local.ssh_key_path 
}
output "instances" { 
    sensitive=true 
    value = azurerm_linux_virtual_machine.instances 
}
output "resource_group" { 
    value = var.resource_group 
}
output "public_security_group" { 
    value = azurerm_network_security_group.sg 
}
output "private_security_group" { 
    value = azurerm_network_security_group.sg-private 
}