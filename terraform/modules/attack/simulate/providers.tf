provider "kubernetes" {
  config_paths = [
    pathexpand("~/.kube/target-kubeconfig")
  ]
}

provider "helm" {
  kubernetes {
    config_paths = [
      pathexpand("~/.kube/target-kubeconfig")
    ]
  }
}