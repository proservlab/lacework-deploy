resource "random_password" "user_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "this" {
  metadata {
    name = "authapp-env-vars"
    namespace = local.app_namespace
  }

  data = {
    USERPWD = random_password.user_password.result
    ADMINPWD = random_password.admin_password.result
  }

  type = "Opaque"
}