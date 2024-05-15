# result
locals {
    result_app_name = "result"
    result_app_namespace = var.app_namespace
}

resource "kubernetes_service_v1" "result" {
    metadata {
        name = local.result_app_name
        labels = {
            app = local.result_app_name
        }
        namespace = local.result_app_namespace
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.this.id
          "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "environment=${var.environment}"
        }
    }
    spec {
        selector = {
            app = local.result_app_name
        }

        # session_affinity = "ClientIP"
        port {
            name = "${local.result_app_name}-service"
            port        = var.result_service_port
            target_port = 80
        }

        type = "LoadBalancer"
        # cluster_ip = "None"
    }

    depends_on = [
        kubernetes_namespace.app,
        kubernetes_namespace.maintenance,
        kubernetes_deployment_v1.result
    ]
}

resource "kubernetes_deployment_v1" "result" {
    metadata {
        name = local.result_app_name
        labels = {
            app = local.result_app_name
        }
        namespace = local.result_app_namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = local.result_app_name
            }
        }

        template {
            metadata {
                labels = {
                app = local.result_app_name
                }
            }

            spec {
                container {
                    image = "dockersamples/examplevotingapp_result:before"
                    name  = local.result_app_name
                    port {
                        container_port = 80
                    }
                }
            }
        }
    }
    depends_on = [
        kubernetes_namespace.app,
        kubernetes_namespace.maintenance,
        kubernetes_deployment_v1.db,
        kubernetes_deployment_v1.redis
    ]
}