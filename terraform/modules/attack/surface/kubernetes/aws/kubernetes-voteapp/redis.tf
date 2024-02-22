# redis
locals {
    redis_app_name = "redis"
    redis_app_namespace = var.app_namespace
}

resource "kubernetes_service_v1" "redis" {
    metadata {
        name = local.redis_app_name
        labels = {
            app = local.redis_app_name
        }
        namespace = local.redis_app_namespace
    }
    spec {
        selector = {
            app = local.redis_app_name
        }

        # session_affinity = "ClientIP"
        port {
            name = "${local.redis_app_name}-service"
            port        = 6379
            target_port = 6379
        }

        # type = "LoadBalancer"
        cluster_ip = "None"
    }

    depends_on = [
        kubernetes_namespace.app,
        kubernetes_namespace.maintenance 
    ] 
}
resource "kubernetes_deployment_v1" "redis" {
    metadata {
        name = local.redis_app_name
        labels = {
            app = local.redis_app_name
        }
        namespace = local.redis_app_namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = local.redis_app_name
            }
        }

        template {
            metadata {
                labels = {
                    app = local.redis_app_name
                }
            }

            spec {
                container {
                    image = "redis:alpine"
                    name  = local.redis_app_name
                    port {
                        container_port = 6379
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