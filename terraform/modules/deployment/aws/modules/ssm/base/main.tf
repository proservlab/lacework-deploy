###########################
# SSM 
###########################

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

resource "aws_ssm_document" "this" {
  name          = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"
  document_type = "Command"

  content = jsonencode(var.payload_type == "bash" ?
    {
        "schemaVersion": "2.2",
        "description": "attack simulation",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "${var.timeout}",
                    "runCommand": [
                        "nohup /bin/sh -c \"echo -n '${var.base64_payload}' | tee /tmp/payload_${var.tag} | base64 -d | gunzip | /bin/bash -\" >/dev/null 2>&1 &"
                    ]
                }
            }
        ]
    } : {
      "schemaVersion": "2.2",
      "description": "attack simulation",
      "mainSteps": [
        {
          "action": "aws:runPowerShellScript",
          "name": "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}",
          "precondition": {
            "StringEquals": [
              "platformType",
              "Windows"
            ]
          },
          "inputs": {
            "timeoutSeconds": "${var.timeout}",
            "runCommand": [
              "Add-Content -Path \"$env:TEMP\\payload_${var.tag}.txt\" -Value '${var.base64_payload}'",
              "Get-Content \"$env:TEMP\\payload_${var.tag}.txt\" | Out-File -FilePath \"$env:TEMP\\payload_${var.tag}.gz\" -Encoding ASCII",
              "Expand-Archive -Path \"$env:TEMP\\payload_${var.tag}.gz\" -DestinationPath \"$env:TEMP\" -Force",
              "powershell.exe -ExecutionPolicy Bypass -File \"$env:TEMP\\payload_${var.tag}.ps1\""
            ]
          }
        }
      ]
    })
}

resource "aws_ssm_document" "this" {
  name          = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "attack simulation",
        "mainSteps": [
            # Step for Linux (Bash)
            {
                "action": "aws:runShellScript",
                "name": "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}_linux",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "${var.timeout}",
                    "runCommand": [
                        "nohup /bin/sh -c \"echo -n '${var.base64_payload}' | tee /tmp/payload_${var.tag} | base64 -d | gunzip | /bin/bash -\" >/dev/null 2>&1 &"
                    ]
                }
            },

            # Step for Windows (Powershell)
            {
                "action": "aws:runPowerShellScript",
                "name": "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}_windows",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Windows"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "${var.timeout}",
                    "runCommand": [
                        "Add-Content -Path \"$env:TEMP\\payload_${var.tag}.txt\" -Value '${var.base64_powershell_payload}'",
                        "Get-Content \"$env:TEMP\\payload_${var.tag}.txt\" | Out-File -FilePath \"$env:TEMP\\payload_${var.tag}.gz\" -Encoding ASCII",
                        "Expand-Archive -Path \"$env:TEMP\\payload_${var.tag}.gz\" -DestinationPath \"$env:TEMP\" -Force",
                        "powershell.exe -ExecutionPolicy Bypass -File \"$env:TEMP\\payload_${var.tag}.ps1\""
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "this" {
    name = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"

    resource_query {
        query = jsonencode({
                    ResourceTypeFilters = [
                        "AWS::EC2::Instance"
                    ]

                    TagFilters = [
                        {
                            Key = "${var.tag}"
                            Values = [
                                "true"
                            ]
                        },
                        {
                            Key = "deployment"
                            Values = [
                                var.deployment
                            ]
                        },
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

resource "aws_ssm_association" "this" {
    association_name = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"

    name = aws_ssm_document.this.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.this.name,
        ]
    }

    compliance_severity = "HIGH"

    # cronjob
    schedule_expression = "${var.cron}"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}