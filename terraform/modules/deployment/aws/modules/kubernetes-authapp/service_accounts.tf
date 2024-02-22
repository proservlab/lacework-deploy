resource "kubernetes_service_account" "this" {
  metadata {
    name = local.service_account
    namespace = local.app_namespace
  }
  
  depends_on = [  
    kubernetes_namespace.this
  ]
}

resource "kubernetes_role" "this" {
  metadata {
    name = "list-pods"
    namespace = local.app_namespace
  }

  rule {
    api_groups = [""]
    resources = ["pods"]
    verbs = ["list"]
  }
  depends_on = [  
    kubernetes_namespace.this
  ]
}

resource "kubernetes_role_binding" "this" {
  metadata {
    name = "authapp-binding"
    namespace = local.app_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "list-pods"
  }

  subject {
    kind = "ServiceAccount"
    name = local.service_account
    namespace = local.app_namespace
  }

  depends_on = [  
    kubernetes_namespace.this
  ]
}
