output "created" {
  value       = var.create
  description = "Was the Active Directory Application created"
}

output "enable_directory_reader" {
  value       = var.enable_directory_reader
  description = "Was the Active Directory Application granted Directory Reader role in Azure AD?"
}

output "application_password" {
  value       = local.application_password
  description = "The Lacework AD Application password"
  sensitive   = true
}

output "application_id" {
  value       = local.client_id
  description = "The Lacework AD Client id"
}

output "service_principal_id" {
  value       = local.service_principal_id
  description = "The Lacework Service Principal id"
}
