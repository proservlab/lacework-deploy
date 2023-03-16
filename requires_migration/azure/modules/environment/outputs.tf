output "az_config_name" {
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_config_name : ""}"
}

output "az_config_client_id" {
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_config_client_id : ""}"
}

output "az_config_client_secret" {
  sensitive = true
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_config_client_secret: ""}"
}

output "az_config_tenant_id" {
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_config_tenant_id: ""}"
}

output "az_config_queue_url" {
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_config_queue_url : ""}"
}

output "az_audit_name" {
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_audit_name : ""}"
}

output "az_audit_client_id" {
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_audit_client_id : ""}"
}


output "az_audit_client_secret" {
  sensitive = true
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_audit_client_secret : ""}"
}

output "az_audit_tenant_id" {
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_audit_tenant_id : ""}"
}

output "az_audit_queue_url" {
  value = "${length(module.lacework-audit-config) > 0 ? module.lacework-audit-config[0].az_audit_queue_url : ""}"
}