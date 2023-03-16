output "ssh_key_path" { value = local.ssh_key_path }
output "public_ip" { value = azurerm_public_ip.myterraformpublicip }
output "resource_group" { value = azurerm_resource_group.myterraformgroup }