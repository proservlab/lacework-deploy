terraform {
  required_providers {
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

module "lacework_aws_ssm_agents_install" {
    source  = "lacework/ssm-agent/aws"
    version = "~> 0.7"

    lacework_agent_tags = {
        environment = var.environment
    }

    aws_resources_tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_resourcegroups_group" "main" {
    name = "main"

    resource_query {
        query = jsonencode({
            ResourceTypeFilters = [
                "AWS::EC2::Instance"
            ]

            TagFilters = [
                {
                    Key = "environment"
                    Values = [
                        var.environment
                    ]
                }
            ]
        })
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
        Token = var.lacework_agent_token
    }

    compliance_severity = "HIGH"
}