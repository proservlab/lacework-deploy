output "users" {
    value = azuread_application.this
}

output "access_keys" {
    sensitive = true
    value = local.access_keys
}

locals {
            access_keys = { for user in var.users : i.name => {
                "clientId": azuread_application.this[each.key].client_id,
                "clientSecret": azuread_service_principal_password[each.key].value,
                "subscriptionId": data.azurerm_subscription.current.subscription_id,
                "tenantId": data.azurerm_subscription.current.tenant_id,
                "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
                "resourceManagerEndpointUrl": "https://management.azure.com/",
                "activeDirectoryGraphResourceId": "https://graph.windows.net/",
                "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
                "galleryEndpointUrl": "https://gallery.azure.com/",
                "managementEndpointUrl": "https://management.core.windows.net/"
            }
        }
}
