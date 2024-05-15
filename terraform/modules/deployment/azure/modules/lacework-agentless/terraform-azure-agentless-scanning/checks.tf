// Provides some guardrails for common misconfiguration
// Those are only available after Terraform v1.5. 

/* When we are doing a non-global/regional deployment, we expect some global resources 
to have been created. One way to check that is to ensure we can reference them via
the global_module_reference attribute.
*/

check "check_global_resource_condition" {
  assert {
    condition = var.global || (
      length(var.global_module_reference.storage_account_id) > 0 &&
      length(var.global_module_reference.scanning_subscription_role_definition_id) > 0 &&
      length(var.global_module_reference.monitored_subscription_role_definition_id) > 0 &&
      length(var.global_module_reference.blob_container_name) > 0 &&
      length(var.global_module_reference.key_vault_id) > 0 &&
      length(var.global_module_reference.sidekick_principal_id) > 0 &&
      length(var.global_module_reference.sidekick_client_id) > 0 &&
      length(var.global_module_reference.key_vault_secret_name) > 0 &&
      length(var.global_module_reference.key_vault_uri) > 0  && 
      length(var.global_module_reference.suffix ) > 0
    )
    error_message = "Some resources have not been referenced correctly during a non-global deployment"
  }
}
