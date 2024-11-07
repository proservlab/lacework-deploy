locals {
  client_id = var.create ? (
    length(azuread_application.lacework) > 0 ? azuread_application.lacework[0].client_id : ""
  ) : ""
  application_password = var.create ? (
    length(azuread_application_password.client_secret) > 0 ? azuread_application_password.client_secret[0].value : ""
  ) : ""
  service_principal_id = var.create ? (
    length(azuread_service_principal.lacework) > 0 ? azuread_service_principal.lacework[0].object_id : ""
  ) : ""
  version_file   = "${abspath(path.module)}/VERSION"
  module_name    = "terraform-azure-ad-application"
  module_version = fileexists(local.version_file) ? file(local.version_file) : ""
}

data "azuread_client_config" "current" {}

## Create a service principal and assigned Directory Reader role in Azure AD
resource "azuread_application" "lacework" {
  count         = var.create ? 1 : 0
  display_name  = var.application_name
  owners        = length(var.application_owners) == 0 ? [data.azuread_client_config.current.object_id] : var.application_owners
  logo_image    = filebase64("${path.module}/imgs/lacework_logo.png")
  marketing_url = "https://www.lacework.com/"
  web {
    homepage_url = "https://www.lacework.com/"
  }
}

resource "azuread_directory_role" "dir_reader" {
  count        = var.create ? (var.enable_directory_reader? 1 : 0 ) : 0
  display_name = "Directory Readers"
}

resource "azuread_service_principal" "lacework" {
  count          = var.create ? 1 : 0
  client_id      = local.client_id
  owners        = length(var.application_owners) == 0 ? [data.azuread_client_config.current.object_id] : var.application_owners
}

resource "azuread_application_password" "client_secret" {
  count                 = var.create ? 1 : 0
  application_id        = azuread_application.lacework[count.index].id
  end_date              = "2299-12-31T01:02:03Z"
  depends_on            = [azuread_service_principal.lacework]
}

# When to use this role? When Granting service principals access to directory where
# Directory.Read.All is not an option. This way we avoid Grant Admin Consent issue.
#
# => https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#directory-readers
resource "azuread_directory_role_assignment" "lacework_dir_reader" {
  count               = var.create ? (var.enable_directory_reader? 1 : 0 ) : 0  
  role_id             = azuread_directory_role.dir_reader[count.index].template_id
  principal_object_id = local.service_principal_id
  depends_on          = [azuread_service_principal.lacework, time_sleep.wait_60_seconds]
}

// Wait for azuread_directory_role_member to be removed to avoid conflict
resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"
}

data "lacework_metric_module" "lwmetrics" {
  name    = local.module_name
  version = local.module_version
}
