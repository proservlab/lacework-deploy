output "users" {
    value = azuread_application.this
}

output "access_keys" {
    sensitive = true
    value = local.access_keys
}

output "application_ids" {
    value = azuread_application.this
}

output "service_principal_ids" {
    value = azuread_service_principal.this
}

output "service_principal_passwords" {
  value     = azuread_service_principal_password.this
  sensitive = true
}

locals {
            access_keys = { for user in var.users : user.name => {
                rendered = <<-EOT
                {
                    "clientId": "${azuread_application.this[user.name].client_id}",
                    "clientSecret": "${azuread_service_principal_password.this[user.name].value}",
                    "subscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                    "tenantId": "${data.azurerm_subscription.current.tenant_id}",
                    "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
                    "resourceManagerEndpointUrl": "https://management.azure.com/",
                    "activeDirectoryGraphResourceId": "https://graph.windows.net/",
                    "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
                    "galleryEndpointUrl": "https://gallery.azure.com/",
                    "managementEndpointUrl": "https://management.core.windows.net/"
                }
                EOT
            }
        }
}
