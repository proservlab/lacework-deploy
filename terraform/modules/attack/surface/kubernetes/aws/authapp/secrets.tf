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
    name = "${local.app_name}-env-vars"
    namespace = local.app_namespace
  }

  data = {
    user_password = try(length(var.user_password), "false") != "false" ? var.user_password : random_password.user_password.result
    admin_password = try(length(var.admin_password), "false") != "false" ? var.admin_password :  random_password.admin_password.result
  }

  type = "Opaque"
}