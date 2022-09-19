# resource "kubernetes_namespace" "namespace" {
#   metadata {
#     name = "lacework"
#   }
# }

# module "lacework_k8s_datacollector" {
#   source    = "lacework/agent/kubernetes"
#   version   = "~> 2.1.0"
#   namespace = "lacework"
#   lacework_access_token = var.lacework_agent_access_token

#   # Add the lacework_agent_tag argument to retrieve the cluster name in the Kubernetes Dossier
#   lacework_agent_tags = {KubernetesCluster: var.cluster-name}
# }

resource "helm_release" "lacework" {
    name       = "lacework"
    repository = "https://lacework.github.io/helm-charts"
    chart      = "lacework-agent"

    create_namespace =  false
    namespace =  "lacework"

    set {
        name  = "laceworkConfig.kubernetesCluster"
        value = var.cluster-name
    }

    set {
        name  = "laceworkConfig.env"
        value = var.environment
    }

    set {
        name  = "laceworkConfig.serverUrl"
        value = var.lacework_server_url
    }

    set_sensitive {
        name  = "laceworkConfig.accessToken"
        value = var.lacework_agent_access_token
    }
}