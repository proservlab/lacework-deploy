
output "resource_group" {
    value = var.resource_group
}

output "automation_account_name" {
    value = azurerm_automation_account.development.name
}
output "automation_princial_id"{
    value = azurerm_user_assigned_identity.development_automation.principal_id
}