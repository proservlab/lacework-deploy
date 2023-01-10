output "name" {
  value = var.lacework_integration_name
}

output "client_id" {
  value = local.application_id
}


output "client_secret" {
  sensitive = true
  value = local.application_password
}

output "tenant_id" {
  value = data.azurerm_subscription.primary.tenant_id
}

output "queue_url" {
  value = ""
}