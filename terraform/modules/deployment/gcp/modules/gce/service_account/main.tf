resource "google_service_account" "default" {
    account_id                          = "${var.environment}-${var.deployment}-${var.name}"
    display_name                        = "${var.environment}-${var.deployment}-${var.name}"
    project                             = var.gcp_project_id
}


resource "google_project_iam_member" "log" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.default.email}"
}

resource "google_project_iam_member" "agent" {
  project = var.gcp_project_id
  role    = "roles/osconfig.serviceAgent"
  member  = "serviceAccount:${google_service_account.default.email}"
}