resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.environment
  }
}

resource "kubernetes_deployment" "vulnerable_privileged_pod" {
  metadata {
    name = "vulnerable-privileged-pod"
    labels = {
      app = "vulnerable-privileged-pod"
    }
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
        match_labels = {
            app = "vulnerable-privileged-pod"
        }
    }

    template {
      metadata {
        labels = {
            app = "vulnerable-privileged-pod"
        }
      }

      spec {
        security_context {
            privileged = true
        }
        container {
            image = "nginx:latest"
            name  = "nginx"
            command = ["tail"]
            args = ["-f", "/dev/null"] 
        }
      }
    }
  }
}