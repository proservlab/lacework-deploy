# maintenance
locals {
    name = "maintenance"
    namespace = var.maintenance_namespace
    role_name = "${local.name}-cluster-read-write-role"
    service_account = "${local.name}-service-account"
}

resource "kubernetes_namespace" "maintenance" {
    metadata {
        name = local.namespace
    }
}

resource "kubernetes_service_account" "maintenance" {
    metadata {
        name = local.service_account
        namespace = local.namespace
    }
}

resource "kubernetes_cluster_role" "maintenance" {
  metadata {
    name = local.role_name
  }

  rule {
    api_groups     =    [
                            "",
                        ]
    resources      =    [
                            "*"
                        ]
    verbs          =    [
                            "get", 
                            "list", 
                            "watch",
                            "create",
                            "update",
                            "patch",
                            "delete"
                        ]
  }
}

resource "kubernetes_cluster_role_binding" "maintenance" {
  metadata {
    name      = "${local.name}-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = local.role_name
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.service_account
  }
}

resource "kubernetes_service_v1" "maintenance" {
    metadata {
        name = local.name
        labels = {
            app = local.name
        }
        namespace = local.namespace
    }
    spec {
        selector = {
            app = local.name
        }
        cluster_ip = "None"
    }

    depends_on = [
      kubernetes_deployment_v1.maintenance
    ]
}
resource "kubernetes_deployment_v1" "maintenance" {
    metadata {
        name = local.name
        labels = {
            app = local.name
        }
        namespace = local.namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = local.name
            }
        }

        template {
            metadata {
                labels = {
                    app = local.name
                }
            }

            spec {
                service_account_name = local.service_account
                container {
                    image = "ubuntu:latest"
                    name  = "maintenance"
                    command =  [ "tail" ]
                    args =  [ "-f", "/dev/null" ]
                }
            }
        }
    }
}