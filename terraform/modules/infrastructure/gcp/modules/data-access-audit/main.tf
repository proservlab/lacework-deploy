resource "google_project_iam_audit_config" "audit" {
    project = var.gcp_project_id
    service = "allServices"
    audit_log_config {
        log_type = "ADMIN_READ"
    }
    audit_log_config {
        log_type = "DATA_READ"
    }
    audit_log_config {
        log_type = "DATA_WRITE"
    }
}