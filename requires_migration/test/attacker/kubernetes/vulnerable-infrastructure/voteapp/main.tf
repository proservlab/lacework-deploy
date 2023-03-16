provider "kubernetes" {
  config_path    = "~/.kube/config"
}

# vote
resource "kubernetes_service_v1" "vote" {
    metadata {
        name = "vote"
        labels = {
            app = "vote"
        }
        # namespace = var.environment
    }
    spec {
        selector = {
            app = "vote"
        }

        # session_affinity = "ClientIP"
        port {
            name = "vote-service"
            port        = 5000
            target_port = 80
        }

        type = "LoadBalancer"
    }
}
resource "kubernetes_deployment_v1" "vote" {
    metadata {
        name = "vote"
        labels = {
            app = "vote"
        }
        # namespace = var.environment
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = "vote"
            }
        }

        template {
            metadata {
                labels = {
                    app = "vote"
                }
            }

            spec {
                container {
                    image = "${aws_ecr_repository.repo.repository_url}:${var.tag}"
                    name  = "vote"
                }
            }
        }
    }

    depends_on = [
      kubernetes_deployment_v1.db,
      kubernetes_deployment_v1.redis
    ]
}

# redis
resource "kubernetes_service_v1" "redis" {
    metadata {
        name = "redis"
        labels = {
            app = "redis"
        }
        # namespace = var.environment
    }
    spec {
        selector = {
            app = "redis"
        }

        # session_affinity = "ClientIP"
        port {
            name = "redis-service"
            port        = 6379
            target_port = 6379
        }

        # type = "LoadBalancer"
        cluster_ip = "None"
    }
}
resource "kubernetes_deployment_v1" "redis" {
    metadata {
        name = "redis"
        labels = {
            app = "redis"
        }
        # namespace = var.environment
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = "redis"
            }
        }

        template {
            metadata {
                labels = {
                app = "redis"
                }
            }

            spec {
                container {
                    image = "redis:alpine"
                    name  = "redis"
                    port {
                        container_port = 6379
                    }
                }
            }
        }
    }
}

# db
resource "kubernetes_service_v1" "db" {
    metadata {
        name = "db"
        labels = {
            app = "db"
        }
        # namespace = var.environment
    }
    spec {
        selector = {
            app = "db"
        }

        # session_affinity = "ClientIP"
        port {
            name = "db"
            port        = 5432
            target_port = 5432
        }

        # type = "LoadBalancer"
        cluster_ip = "None"
    }
}
resource "kubernetes_persistent_volume_claim_v1" "db" {
    metadata {
        name = "db-data-claim"
        # namespace = var.environment
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
        name = "db"
        labels = {
            app = "db"
        }
        # namespace = var.environment
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = "db"
            }
        }

        template {
            metadata {
                labels = {
                    app = "db"
                }
            }

            spec {
                container {
                    image = "postgres:9.4"
                    name  = "db"
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
                        name = "db-data-claim"
                        mount_path = "/var/lib/postgresql/data"
                    }
                }
                volume {
                    name = "db-data-claim"
                    persistent_volume_claim {
                        claim_name = "db-data-claim"
                    }
            
                }
            }
        }
    }
}

# result
resource "kubernetes_service_v1" "result" {
    metadata {
        name = "result"
        labels = {
            app = "result"
        }
        # namespace = var.environment
    }
    spec {
        selector = {
            app = "result"
        }

        # session_affinity = "ClientIP"
        port {
            name = "result-service"
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
        name = "result"
        labels = {
            app = "result"
        }
        # namespace = var.environment
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = "result"
            }
        }

        template {
            metadata {
                labels = {
                app = "result"
                }
            }

            spec {
                container {
                    image = "dockersamples/examplevotingapp_result:before"
                    name  = "result"
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

# worker
resource "kubernetes_service_v1" "worker" {
    metadata {
        name = "worker"
        labels = {
            app = "worker"
        }
        # namespace = var.environment
    }
    spec {
        selector = {
            app = "worker"
        }
        cluster_ip = "None"
    }

    depends_on = [
      kubernetes_deployment_v1.worker
    ]
}
resource "kubernetes_deployment_v1" "worker" {
    metadata {
        name = "worker"
        labels = {
            app = "worker"
        }
        # namespace = var.environment
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = "worker"
            }
        }

        template {
            metadata {
                labels = {
                app = "worker"
                }
            }

            spec {
                container {
                    image = "dockersamples/examplevotingapp_worker"
                    name  = "worker"
                }
            }
        }
    }

    depends_on = [
      kubernetes_deployment_v1.db,
      kubernetes_deployment_v1.redis
    ]
}

# maintenance
resource "kubernetes_service_v1" "maintenance" {
    metadata {
        name = "maintenance"
        labels = {
            app = "maintenance"
        }
        # namespace = var.environment
    }
    spec {
        selector = {
            app = "maintenance"
        }
        cluster_ip = "None"
    }

    depends_on = [
      kubernetes_deployment_v1.maintenance
    ]
}
resource "kubernetes_deployment_v1" "maintenance" {
    metadata {
        name = "maintenance"
        labels = {
            app = "maintenance"
        }
        # namespace = var.environment
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = "maintenance"
            }
        }

        template {
            metadata {
                labels = {
                app = "maintenance"
                }
            }

            spec {
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