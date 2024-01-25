resource "kubernetes_service_account" "web_service" {
  metadata {
    name = var.service_account
    namespace = local.app_namespace
  }
  depends_on = [  
    kubernetes_namespace.this
  ]
}

resource "kubernetes_service_account" "worker_logger" {
  metadata {
    name = "worker-logger"
    namespace = local.app_namespace
  }
  depends_on = [  
    kubernetes_namespace.this
  ]
}

resource "kubernetes_role" "list_pods" {
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

resource "kubernetes_role_binding" "web_service_binding" {
  metadata {
    name = "web-service-binding"
    namespace = local.app_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "list-pods"
  }

  subject {
    kind = "ServiceAccount"
    name = var.service_account
    namespace = local.app_namespace
  }

  depends_on = [  
    kubernetes_namespace.this
  ]
}

// Annotate Kubernetes service account with IAM role
resource "kubernetes_service_account" "s3_access" {
  metadata {
    name = "web-service"
    namespace = local.app_namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.s3_access.arn
    }
  }

  depends_on = [  
    kubernetes_namespace.this
  ]
}
