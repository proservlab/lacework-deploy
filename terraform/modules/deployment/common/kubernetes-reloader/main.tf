resource "helm_release" "reloader" {
  name             = var.app
  repository       = "https://stakater.github.io/stakater-charts"
  chart            = "reloader"
  version          = "v1.0.63"
  namespace        = var.app_namespace
  create_namespace = true

  set {
    name  = "reloader.ignoreNamespaces"
    value = join(",", var.ignore_namespaces)
    type  = "string"
  }

}