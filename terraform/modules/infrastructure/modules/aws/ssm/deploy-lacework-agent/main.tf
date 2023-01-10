resource "random_uuid" "agent" {
}

resource "lacework_agent_access_token" "agent" {
    count = can(length(var.lacework_agent_access_token)) ? 0 : 1
    name = "${var.environment}-${random_uuid.agent.id}-daemonset-agent-access-token"
}

module "lacework_aws_ssm_agents_install" {
    source  = "lacework/ssm-agent/aws"
    version = "~> 0.7"

    # tags to add to the lacework data collector
    lacework_agent_tags = {
        Environment = var.environment
    }

    # tags to add to created resources for this module
    aws_resources_tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_resourcegroups_group" "main" {
    name = "main"

    resource_query {
        query = jsonencode(var.resource_query)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "lacework_aws_ssm_agents_install" {
    association_name = "install-lacework-agents-group"

    name = module.lacework_aws_ssm_agents_install.ssm_document_name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.main.name,
        ]
    }

    parameters = {
        Token = can(length(var.lacework_agent_access_token)) ? var.lacework_agent_access_token : lacework_agent_access_token.agent[0].token
        Serverurl = var.lacework_server_url
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}