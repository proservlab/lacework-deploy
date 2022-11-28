resource "kubernetes_deployment" "attacker_kalilinux_pod" {
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