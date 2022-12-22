# worker
locals {
    worker_app_name = "worker"
    worker_app_namespace = var.app_namespace
}

resource "kubernetes_service_v1" "worker" {
    metadata {
        name = local.worker_app_name
        labels = {
            app = local.worker_app_name
        }
        namespace = local.worker_app_namespace
    }
    spec {
        selector = {
            app = local.worker_app_name
        }
        cluster_ip = "None"
    }

    depends_on = [
      kubernetes_deployment_v1.worker
    ]
}
resource "kubernetes_deployment_v1" "worker" {
    metadata {
        name = local.worker_app_name
        labels = {
            app = local.worker_app_name
        }
        namespace = local.worker_app_namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = local.worker_app_name
            }
        }

        template {
            metadata {
                labels = {
                app = local.worker_app_name
                }
            }

            spec {
                container {
                    image = "dockersamples/examplevotingapp_worker"
                    name  = local.worker_app_name
                }
            }
        }
    }

    depends_on = [
      kubernetes_deployment_v1.db,
      kubernetes_deployment_v1.redis
    ]
}