# db
locals {
    db_app_name = "db"
    db_app_namespace = var.app_namespace
    db_app_role_name = "${local.db_app_name}-cluster-read-role"
    db_app_service_account = "${local.db_app_name}-service-account"  
}

resource "kubernetes_service_account" "db" {
    metadata {
        name = local.db_app_service_account
        namespace = local.db_app_namespace
    }

    depends_on = [
      kubernetes_namespace.app,
      kubernetes_namespace.maintenance
    ]
}

resource "kubernetes_cluster_role" "db" {
    metadata {
        name = local.db_app_role_name
    }

    rule {
        api_groups     =    [
                                "",
                            ]
        resources      =    [
                                "services",
                                "pods"
                            ]
        verbs          =    [
                                "get", 
                                "list", 
                                "watch",
                            ]
    }
    
}

resource "kubernetes_cluster_role_binding" "db" {
  metadata {
    name      = "${local.db_app_name}-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = local.db_app_role_name
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.db_app_service_account
    namespace = local.db_app_namespace
  }

  depends_on = [
    kubernetes_namespace.app,
    kubernetes_namespace.maintenance 
  ]   
}

resource "kubernetes_service_v1" "db" {
    metadata {
        name = local.db_app_name
        labels = {
            app = local.db_app_name
        }
        namespace = local.db_app_namespace
    }
    spec {
        selector = {
            app = local.db_app_name
        }

        # session_affinity = "ClientIP"
        port {
            name = local.db_app_name
            port        = 5432
            target_port = 5432
        }

        # type = "LoadBalancer"
        cluster_ip = "None"
    }

    depends_on = [
        kubernetes_namespace.app,
        kubernetes_namespace.maintenance 
    ] 
}
resource "kubernetes_persistent_volume_claim_v1" "db" {
    metadata {
        name = "${local.db_app_name}-data-claim"
        namespace = local.db_app_namespace
    }
    spec {
        access_modes = ["ReadWriteOnce"]
        resources {
            requests = {
                storage = "1Gi"
            }
        }
    }

    depends_on = [
        kubernetes_namespace.app,
        kubernetes_namespace.maintenance 
    ] 
}
resource "kubernetes_deployment_v1" "db" {
    metadata {
        name = local.db_app_name
        labels = {
            app = local.db_app_name
        }
        namespace = local.db_app_namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = local.db_app_name
            }
        }

        template {
            metadata {
                labels = {
                    app = local.db_app_name
                }
            }

            spec {
                container {
                    image = "postgres:9.4"
                    name  = local.db_app_name
                    port {
                        container_port = 5432
                    }
                    env {
                        name = "PGDATA"
                        value = "/var/lib/postgresql/data/pgdata"
                    }
                    env {
                        name = "POSTGRES_USER"
                        value = "postgres"
                    }

                    env {
                        name = "POSTGRES_PASSWORD"
                        value = "postgres"
                    }

                    env {
                        name = "POSTGRES_HOST_AUTH_METHOD"
                        value = "trust"
                    }
                    volume_mount {
                        name = "${local.db_app_name}-data-claim"
                        mount_path = "/var/lib/postgresql/data"
                    }
                }
                volume {
                    name = "${local.db_app_name}-data-claim"
                    persistent_volume_claim {
                        claim_name = "${local.db_app_name}-data-claim"
                    }
                }
            }
        }
    }

    depends_on = [
        kubernetes_namespace.app,
        kubernetes_namespace.maintenance 
    ] 
}