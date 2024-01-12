# create the syscall_config file
resource "local_file" "syscall_config" {
    content  = var.syscall_config
    filename = "${path.module}/helm-charts/lacework-agent-windows/config/syscall_config.yaml"
}

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

# create a token for the daemonset
resource "lacework_agent_access_token" "agent" {
    # count = can(length(var.lacework_agent_access_token)) ? 0 : 1
    name = "daemonset-windows-agent-access-token-${random_string.this.id}-${var.environment}-${var.deployment}"
}

# use the local chart to apply (current workaround for syscall_config.yaml)
resource "helm_release" "lacework" {
    name       = "lacework-agent-windows-${var.environment}-${var.deployment}"
    repository = "${path.module}/helm-charts"
    chart      = "lacework-agent-windows"
    version    = "1.4.0"

    create_namespace =  true
    namespace =  "lacework-windows"
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
        value = true
    }

    set {
        name  = "windowsAgent.image.repository"
        value = var.lacework_image_repository
    }

    set {
        name  = "windowsAgent.image.tag"
        value = var.lacework_image_tag
    }


    depends_on = [
        local_file.syscall_config
    ]
}