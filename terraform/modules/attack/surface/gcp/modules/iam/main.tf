
# create service accounts
resource "google_service_account" "users" {
  for_each = { for i in var.users : i.name => i }
  project = var.gcp_project_id
  account_id   = each.key
  display_name = "service account"

}

resource "google_service_account_key" "keys" {
  for_each = google_service_account.users
  service_account_id = each.key
}

resource "google_project_iam_binding" "roles" {
  for_each = google_service_account.users
  project = var.gcp_project_id
  role    = [ for i in var.users: i.policy if i.name == each.key ][0]
  members = [
    "serviceAccount:${each.value.email}"
  ]
}
locals {
  access_keys = { for i in var.users : i.name => {
                    rendered =  <<-EOT
                                ${base64decode(google_service_account_key.keys[i.name].private_key)}
                                EOT
                  } 
                }
}

resource "null_resource" "log" {
  triggers = {
    log_message = jsonencode(local.access_keys)
  }

  provisioner "local-exec" {
    command = "echo '${jsonencode(local.access_keys)}'"
  }
}