locals {
  enable_service = false
}
resource "kubernetes_deployment" "vulnerable_log4shell_pod" {
  metadata {
    name = "vulnerable-log4shell-pod"
    labels = {
      app = "vulnerable-log4shell-pod"
    }
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
        match_labels = {
            app = "vulnerable-log4shell-pod"
        }
    }

    template {
      metadata {
        labels = {
            app = "vulnerable-log4shell-pod"
        }
      }

      spec {
        container {
            image = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
            name  = "vulnerable-log4shell-pod"
            command = ["java"]
            args = ["-jar", "/app/spring-boot-application.jar"]

            port {
                container_port = 8080
            }
        }
      }
    }
  }
}


resource "kubernetes_service_v1" "vulnerable_log4shell_pod" {
    count = local.enable_service == true ? 1 : 0
    metadata {
        name = "vulnerable-log4shell-pod"
        labels = {
            app = "vulnerable-log4shell-pod"
        }
        # namespace = var.environment
    }
    spec {
        selector = {
            app = "vulnerable-log4shell-pod"
        }

        # session_affinity = "ClientIP"
        port {
            name = "log4shell-service"
            port        = 8080
            target_port = 8080
        }

        type = "LoadBalancer"
    }
}