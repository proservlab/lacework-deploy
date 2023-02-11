resource "kubernetes_namespace" "app" {
    metadata {
        name = var.app_namespace
    }
}

resource "kubernetes_namespace" "maintenance" {
    metadata {
        name = var.maintenance_namespace
    }
}