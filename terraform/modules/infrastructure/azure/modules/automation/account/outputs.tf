
output "public_automation_account_name" {
    value = azurerm_automation_account.development.name
}
output "public_automation_princial_id"{
    value = azurerm_user_assigned_identity.development_automation.principal_id
}
output "private_automation_account_name"{
    value = azurerm_automation_account.development_private.name
}
output "private_automation_princial_id"{
    value = azurerm_user_assigned_identity.private_development_automation.principal_id
}