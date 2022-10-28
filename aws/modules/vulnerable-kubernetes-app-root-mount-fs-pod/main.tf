resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.environment
  }
}

resource "kubernetes_deployment" "vulnerable_root_mount_fs_pod" {
  metadata {
    name = "vulnerable-root-mount-fs-pod"
    labels = {
      app = "vulnerable-root-mount-fs-pod"
    }
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
        match_labels = {
            app = "vulnerable-root-mount-fs-pod"
        }
    }

    template {
      metadata {
        labels = {
            app = "vulnerable-root-mount-fs-pod"
        }
      }

      spec {
        container {
            image = "nginx:latest"
            name  = "nginx"
            command = ["tail"]
            args = ["-f", "/dev/null"] 
            volume_mount {
              name = "test-volume"
              mount_path = "/host"
            }
        }
        volume {
          name = "test-volume"
          host_path {
            path = "/"
            type = "directory"
          }
        }
      }
    }
  }
}