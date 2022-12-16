# result
locals {
    name = "result"
    namespace = var.app_namespace
    role_name = "${local.name}-cluster-read-role"
    service_account = "${local.name}-service-account"
}

resource "kubernetes_service_v1" "result" {
    metadata {
        name = local.name
        labels = {
            app = local.name
        }
        namespace = local.namespace
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.app_lb.id
          "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "environment=${var.environment}"
        }
    }
    spec {
        selector = {
            app = local.name
        }

        # session_affinity = "ClientIP"
        port {
            name = "${local.name}-service"
            port        = 5001
            target_port = 80
        }

        type = "LoadBalancer"
        # cluster_ip = "None"
    }

    depends_on = [
      kubernetes_deployment_v1.result
    ]
}

resource "kubernetes_deployment_v1" "result" {
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
                    image = "dockersamples/examplevotingapp_result:before"
                    name  = local.name
                    port {
                        container_port = 80
                    }
                }
            }
        }
    }
    depends_on = [
      kubernetes_deployment_v1.db,
      kubernetes_deployment_v1.redis
    ]
}