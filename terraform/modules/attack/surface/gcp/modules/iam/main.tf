
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

resource "google_project_iam_member" "roles" {
  for_each = toset(flatten([
    for user in var.users : [
      for role in user.roles : {
        name = user.name
        role = role
      }
    ]
  ]))
  project = var.gcp_project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.users[each.value.name].email}"
}

locals {
  access_keys = { for i in var.users : i.name => {
                    rendered =  <<-EOT
                                ${base64decode(google_service_account_key.keys[i.name].private_key)}
                                EOT
                  } 
                }
}

