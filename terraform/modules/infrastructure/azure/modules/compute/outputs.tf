output "ssh_key_path" { value = local.ssh_key_path }
output "instances" { value = azurerm_linux_virtual_machine.instances }
output "resource_group" { value = azurerm_resource_group.rg }
output "public_security_group" { value = azurerm_network_security_group.sg }