
locals {
        user_roles = [ for i in var.users: { for r in i.roles: "${i.name}-${r}" => {
                name = i.name
                role = r
        }} ][0]
}

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
  for_each = local.user_roles
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

