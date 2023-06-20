resource "helm_release" "calico" {
  name        = "calico-${var.environment}-${var.deployment}"
  
  create_namespace =  true
  namespace   = "tigera-operator"
  repository  = "https://docs.projectcalico.org/charts"
  chart       = "tigera-operator"
  force_update = true
  

  set{
    name = "installation.kubernetesProvider"
    value = "EKS"
  }
  
}