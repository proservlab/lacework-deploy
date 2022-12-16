# redis
locals {
    name = "result"
    namespace = var.app_namespace
    role_name = "${local.name}-cluster-read-role"
    service_account = "${local.name}-service-account"
}

resource "kubernetes_service_v1" "redis" {
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
            name = "${local.name}-service"
            port        = 6379
            target_port = 6379
        }

        # type = "LoadBalancer"
        cluster_ip = "None"
    }
}
resource "kubernetes_deployment_v1" "redis" {
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
                    image = "redis:alpine"
                    name  = local.name
                    port {
                        container_port = 6379
                    }
                }
            }
        }
    }
}