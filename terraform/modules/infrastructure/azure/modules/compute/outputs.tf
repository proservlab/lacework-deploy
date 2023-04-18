output "ssh_key_path" { 
    value = local.ssh_key_path 
}
output "instances" { 
    sensitive = false
    value = [for instance in azurerm_linux_virtual_machine.instances : {
                name       = instance.name
                public_ip  = instance.public_ip_address
                admin_user = instance.admin_username
            }]
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