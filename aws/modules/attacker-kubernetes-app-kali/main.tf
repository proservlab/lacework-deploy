resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.environment
  }
}

resource "kubernetes_deployment" "vulnerable_log4shell_pod" {
  metadata {
    name = "attacker-kalilinux-pod"
    labels = {
      app = "attacker-kalilinux-pod"
    }
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
        match_labels = {
            app = "attacker-kalilinux-pod"
        }
    }

    template {
      metadata {
        labels = {
            app = "attacker-kalilinux-pod"
        }
      }

      spec {
        container {
            image = "kalilinux/kali-rolling"
            name  = "attacker-kalilinux-pod"
            command = ["tail"]
            args = ["-f", "/dev/null"] 
        }
      }
    }
  }
}


resource "kubernetes_service_v1" "vulnerable_log4shell_pod" {
    metadata {
        name = "vulnerable-log4shell-pod"
        labels = {
            app = "vulnerable-log4shell-pod"
        }
    }
    spec {
        selector = {
            app = "vulnerable-log4shell-pod"
        }

        # session_affinity = "ClientIP"
        port {
            name = "vulnerable-log4shell-pod"
            port        = 8080
            target_port = 8080
        }

        # type = "LoadBalancer"
        cluster_ip = "None"
    }
}