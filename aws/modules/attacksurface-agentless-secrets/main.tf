
resource "aws_ssm_document" "deploy_secret_ssh_private" {
  name          = "deploy_secret_ssh_private"
  document_type = "Command"

  content = <<DOC
  {
    "schemaVersion": "1.2",
    "description": "Setup secret ssh private key",
    "parameters": {

    },
    "runtimeConfig": {
      "aws:runShellScript": {
        "properties": [
          {
            "id": "0.aws:runShellScript",
            "runCommand": ["touch /tmp/private", "touch /tmp/private2"]
          }
        ]
      }
    }
  }
DOC
}

resource "aws_ssm_document" "deploy_secret_ssh_public" {
  name          = "deploy_secret_ssh_public"
  document_type = "Command"

  content = <<DOC
  {
    "schemaVersion": "1.2",
    "description": "Setup secret ssh public key",
    "parameters": {

    },
    "runtimeConfig": {
      "aws:runShellScript": {
        "properties": [
          {
            "id": "0.aws:runShellScript",
            "runCommand": ["touch /tmp/public", "touch /tmp/public2"]
          }
        ]
      }
    }
  }
DOC
}

resource "aws_resourcegroups_group" "deploy_secret_ssh_private" {
    name = "deploy_secret_ssh_private"

    resource_query {
        query = jsonencode(var.resource_query_deploy_secret_ssh_private)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "deploy_secret_ssh_private" {
    association_name = "deploy_secret_ssh_private"

    name = aws_ssm_document.deploy_secret_ssh_private.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.deploy_secret_ssh_private.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}

resource "aws_resourcegroups_group" "deploy_secret_ssh_public" {
    name = "deploy_secret_ssh_public"

    resource_query {
        query = jsonencode(var.resource_query_deploy_secret_ssh_public)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "deploy_secret_ssh_public" {
    association_name = "deploy_secret_ssh_public"

    name = aws_ssm_document.deploy_secret_ssh_public.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.deploy_secret_ssh_public.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}