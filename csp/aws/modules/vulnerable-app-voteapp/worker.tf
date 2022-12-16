# worker
locals {
    name = "vote"
    namespace = var.app_namespace
    role_name = "${local.name}-cluster-read-role"
    service_account = "${local.name}-service-account"
}

resource "kubernetes_service_v1" "worker" {
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
      kubernetes_deployment_v1.worker
    ]
}
resource "kubernetes_deployment_v1" "worker" {
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
                    image = "dockersamples/examplevotingapp_worker"
                    name  = local.name
                }
            }
        }
    }

    depends_on = [
      kubernetes_deployment_v1.db,
      kubernetes_deployment_v1.redis
    ]
}