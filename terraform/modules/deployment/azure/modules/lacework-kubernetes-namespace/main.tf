resource "kubernetes_namespace" "lacework" {
  metadata {
    name = "lacework"
  }
}