resource "aws_ssm_document" "deploy_inspector_agent" {
  name          = "deploy_inspector_agent_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "deploy inspector agent",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "deploy_inspector_agent_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "wget https://inspector-agent.amazonaws.com/linux/latest/install -P /tmp 2>/dev/null || curl -O  https://inspector-agent.amazonaws.com/linux/latest/install -o /tmp/install",
                        "/bin/bash /tmp/install"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "deploy_inspector_agent" {
    name = "deploy_inspector_agent_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_deploy_inspector_agent)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "deploy_inspector_agent" {
    association_name = "deploy_inspector_agent_${var.environment}_${var.deployment}"

    name = aws_ssm_document.deploy_inspector_agent.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.deploy_inspector_agent.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    # schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    # apply_only_at_cron_interval = false
}