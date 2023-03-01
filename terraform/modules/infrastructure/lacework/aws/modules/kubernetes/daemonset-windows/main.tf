# create the syscall_config file
resource "local_file" "syscall_config" {
    content  = var.syscall_config
    filename = "${path.module}/helm-charts/lacework-agent-windows/config/syscall_config.yaml"
}

# create a token for the daemonset
resource "lacework_agent_access_token" "agent" {
    # count = can(length(var.lacework_agent_access_token)) ? 0 : 1
    name = "daemonset-aws-windows-agent-access-token-${var.environment}-${var.deployment}"
}

# use the local chart to apply (current workaround for syscall_config.yaml)
resource "helm_release" "lacework" {
    name       = "lacework-${var.environment}-${var.deployment}"
    repository = "${path.module}/helm-charts"
    chart      = "lacework-agent-windows"
    version    = "1.4.0"

    create_namespace =  false
    namespace =  "lacework"
    force_update = true

    set {
        name  = "windowsAgent.agentConfig.kubernetesCluster"
        value = var.cluster_name
    }

    set {
        name  = "windowsAgent.agentConfig.env"
        value = var.environment
    }

    set {
        name  = "windowsAgent.agentConfig.serverUrl"
        value = var.lacework_server_url
    }

    set_sensitive {
        name  = "windowsAgent.agentConfig.accessToken"
        # value = can(length(var.lacework_agent_access_token)) ? var.lacework_agent_access_token : lacework_agent_access_token.agent[0].token
        value = lacework_agent_access_token.agent.token
    }

    set {
        name  = "windowsAgent.enable"
        value = var.lacework_cluster_agent_enable
    }

    set {
        name  = "windowsAgent.image.repository"
        value = var.lacework_cluster_agent_image_repository
    }

    # set {
    #     name  = "windowsAgent.clusterType"
    #     value = var.lacework_cluster_agent_cluster_type
    # }

    # set {
    #     name  = "windowsAgent.clusterRegion"
    #     value = var.lacework_cluster_agent_cluster_region
    # }

    set {
        name  = "windowsAgent.image.repository"
        value = var.lacework_image_repository
    }

    depends_on = [
        local_file.syscall_config
    ]
}