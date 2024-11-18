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
                        "$outputPath = \"$env:TEMP\\payload_${var.tag}.gz\"",
                        "$bytes = [System.Convert]::FromBase64String('${var.base64_powershell_payload}')",
                        "[System.IO.File]::WriteAllBytes($outputPath, $bytes)",
                        "$outputDecompressedPath = \"$env:TEMP\\payload_${var.tag}.ps1\"",
                        "Add-Type -AssemblyName System.IO.Compression.FileSystem",
                        "$gzipFile = $null",
                        "$gzipStream = $null",
                        "$decompressedFile = $null",
                        "try {",
                            "$gzipFile = [System.IO.File]::OpenRead($outputPath)",
                            "$gzipStream = [System.IO.Compression.GZipStream]::new($gzipFile, [System.IO.Compression.CompressionMode]::Decompress)",
                            "$decompressedFile = [System.IO.File]::Create($outputDecompressedPath)",
                            "$gzipStream.CopyTo($decompressedFile)",
                            "Write-Output \"Decompression successful! Decompressed file saved to $outputDecompressedPath\"",
                            "$arguments = '-ExecutionPolicy Bypass -File \"{0}\"' -f \"$env:TEMP\\payload_${var.tag}.ps1\"",
                            "Start-Process powershell.exe -ArgumentList $arguments -WindowStyle Hidden",
                        "} catch {",
                            "Write-Output \"Failed to decompress the file: $_\" | Out-File \"$env:TEMP\\${var.tag}.err\"",
                        "} finally {",
                            "if ($gzipStream) { $gzipStream.Close(); $gzipStream.Dispose() }",
                            "if ($gzipFile) { $gzipFile.Close(); $gzipFile.Dispose() }",
                            "if ($decompressedFile) { $decompressedFile.Close(); $decompressedFile.Dispose() }",
                        "}",
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