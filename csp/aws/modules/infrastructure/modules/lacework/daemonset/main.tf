resource "lacework_agent_access_token" "agent" {
    count = can(length(var.lacework_agent_access_token)) ? 0 : 1
    name = "${var.environment}-daemonset-agent-access-token"
}

resource "helm_release" "lacework" {
    name       = "${var.environment}-lacework"
    repository = "https://lacework.github.io/helm-charts"
    chart      = "lacework-agent"

    create_namespace =  false
    namespace =  "lacework"
    force_update = true

    set {
        name  = "laceworkConfig.kubernetesCluster"
        value = var.cluster_name
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
        value = can(length(var.lacework_agent_access_token)) ? var.lacework_agent_access_token : lacework_agent_access_token.agent[0].token
    }

    set {
        name  = "clusterAgent.enable"
        value = var.lacework_cluster_agent_enable
    }

    set {
        name  = "clusterAgent.image.repository"
        value = var.lacework_cluster_agent_image_repository
    }

    set {
        name  = "clusterAgent.clusterType"
        value = var.lacework_cluster_agent_cluster_type
    }

    set {
        name  = "clusterAgent.clusterRegion"
        value = var.lacework_cluster_agent_cluster_region
    }

    set {
        name  = "image.repository"
        value = var.lacework_image_repository
    }
}