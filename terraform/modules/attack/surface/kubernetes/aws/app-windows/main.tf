##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../../../context/deployment"
}

# manage the app deployment to this cluster in separate project - things that could be applied here are:
# - token hardening
# - default namespaces
# - default app deployment daemonsets

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.environment
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "terraform-example-app-windows"
    labels = {
      app = "example-app-windows"
    }
    namespace = var.environment
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.environment}-app-windows"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.environment}-app-windows"
          tier = "backend"
          track = "stable"
        }
      }

      spec {
        container {
          image = "mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022"
          name  = "iis"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 80
          }
          command = [
                      "powershell.exe",
                      "-command",
                      "\"Add-WindowsFeature Web-Server; Invoke-WebRequest -UseBasicParsing -Uri 'https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.6/ServiceMonitor.exe' -OutFile 'C:\\ServiceMonitor.exe'; echo '<html><body><br/><br/><H1>Our first pods running on Windows managed node groups! Powered by Windows Server LTSC 2022.<H1></body><html>' > C:\\inetpub\\wwwroot\\iisstart.htm; C:\\ServiceMonitor.exe 'w3svc'; \""
                    ]
        }
        node_selector = {
          "kubernetes.io/os" = "windows"
        }
        toleration {
          effect   = "NoSchedule"
          key      = "os"
          operator = "Equal"
          value    = "windows"
        }
      }
    }
  }
}