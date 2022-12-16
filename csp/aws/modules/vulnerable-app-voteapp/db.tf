# db
locals {
    name = "db"
    namespace = var.app_namespace
    role_name = "${local.name}-cluster-read-role"
    service_account = "${local.name}-service-account"
}

resource "kubernetes_service_account" "db" {
    metadata {
        name = local.service_account
        namespace = local.namespace
    }
}

resource "kubernetes_cluster_role" "db" {
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
                            ]
    }
}

resource "kubernetes_cluster_role_binding" "db" {
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

resource "kubernetes_service_v1" "db" {
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

        # session_affinity = "ClientIP"
        port {
            name = local.name
            port        = 5432
            target_port = 5432
        }

        # type = "LoadBalancer"
        cluster_ip = "None"
    }
}
resource "kubernetes_persistent_volume_claim_v1" "db" {
    metadata {
        name = "${local.name}-data-claim"
        namespace = local.namespace
    }
    spec {
        access_modes = ["ReadWriteOnce"]
        resources {
            requests = {
                storage = "1Gi"
            }
        }
    }
}
resource "kubernetes_deployment_v1" "db" {
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
                container {
                    image = "postgres:9.4"
                    name  = local.name
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
                        name = "${local.name}-data-claim"
                        mount_path = "/var/lib/postgresql/data"
                    }
                }
                volume {
                    name = "${local.name}-data-claim"
                    persistent_volume_claim {
                        claim_name = "${local.name}-data-claim"
                    }
                }
            }
        }
    }
}