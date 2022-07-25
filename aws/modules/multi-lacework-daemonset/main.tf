terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.22.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "helm_release" "lacework" {
    name       = "lacework"
    repository = "https://lacework.github.io/helm-charts"
    chart      = "lacework-agent"

    create_namespace =  true
    namespace =  "lacework"

    set {
        name  = "laceworkConfig.accessToken"
        value = var.lacework_agent_access_token
    }

    # set {
    #     name  = "laceworkConfig.serverUrl"
    #     value = "api.lacework.net"
    # }

    set {
        name  = "laceworkConfig.kubernetesCluster"
        value = var.cluster-name
    }

    set {
        name  = "laceworkConfig.env"
        value = var.environment
    }

    # set_sensitive {
    #     name  = "laceworkConfig.accessToken"
    #     value = lacework_agent_access_token.cluster.token
    # }
}

# module "lacework_k8s_datacollector" {
#   source  = "lacework/agent/kubernetes"
#   version = "~> 1.0"
#   namespace = "lacework"

#   lacework_access_token = lacework_agent_access_token.cluster.token

#   # Add the lacework_agent_tag argument to retrieve the cluster name in the Kubernetes Dossier
#   lacework_agent_tags = {KubernetesCluster: var.cluster-name}

#   pod_cpu_request = "200m"
#   pod_mem_request = "512Mi"
#   pod_cpu_limit   = "1"
#   pod_mem_limit   = "1024Mi"
# }