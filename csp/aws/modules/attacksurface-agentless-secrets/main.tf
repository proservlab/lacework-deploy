locals {
    ssh_private_key = "LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUNGd0FBQUFkemMyZ3RjbgpOaEFBQUFBd0VBQVFBQUFnRUE1aE9VUmltdCt5NEN3VXcxNjh4VndjTEhGLzlnZ3d5M3EvSW9BZUJqakNJRlV5eTJSVlRqClVHZzBqTThwdlZ0N3paZHk1NlN2ajBQMmx6NjFoU1RCbUZFcm14c0NZVUZjTEdnT2UzVzFCZUpQZHROWkQyTGdkVk41SmwKVHcyV2YzM2phSTlSQ1RRaXZtc2R2L05jZmttTGpSV0Z2Y2h4OXg1N3l1VXBwWklXSndUWGlJSlRmWE1lakIrY0pNRXNhTQpabUhpL2o1Nk9ZTitEZEpEYmxMMVNKRHBrS1BLU2x5eUUrWEExRU1zUFc2U01wZXpUdXVIUzAxTW1lbFJ4cy96dHhFclNWCitrOWpJbmRvRHJobWpJSTRXWFRYL2dzNjFaVG1lc0Zsc2Q2b1JrZVFLWHBrM255WllLL3pDWVVmTlc0K2tGTkd1NmlyTmEKSGtlMFlMSklaaG9LaUtHejZtYlhvY3pJZG94aHlyN2E2ZmI0Z3NRR3J1ajFMVUtSTjZMbGFjb2twWEpuM2pkeTBSQmZ6bwo0N1AvOUtBYXQ3aHl6ZkZQSThSZyt4cnd1bURBUU9lanhsSU95WS9GVXFHeFNzYjRFaVpsTXRGZmh4WEt1VWpnTHVpcWZiClIzUm1icGFZUXhNaGQwUmltNXQ0RFVTZ0pPMWJudEczTW5zbkhhNytOSys3Uyt5WWwrcmZCaWtmMEpGT0dEZXpYZk9WMXkKbDJjTzR5bmt3Qnhwc0lIK1Ura3RKWU9Vb21hSGFzTDBrSmoxZXl0SmFWeUJRWDF0VVB1cGlUbStUa3dGZ2lUVlBPVHdmRApiOFAzb3Ywc2VpdHNrSHFKbGdNSW9ZL2xyUFVvdDZHclhqWHRVdnhkb0kxMWJGQjViWDduc0lXOEpaZkVjNnRKYWE5UmptClVBQUFkSUlzSXFQQ0xDS2p3QUFBQUhjM05vTFhKellRQUFBZ0VBNWhPVVJpbXQreTRDd1V3MTY4eFZ3Y0xIRi85Z2d3eTMKcS9Jb0FlQmpqQ0lGVXl5MlJWVGpVR2cwak04cHZWdDd6WmR5NTZTdmowUDJsejYxaFNUQm1GRXJteHNDWVVGY0xHZ09lMwpXMUJlSlBkdE5aRDJMZ2RWTjVKbFR3MldmMzNqYUk5UkNUUWl2bXNkdi9OY2ZrbUxqUldGdmNoeDl4NTd5dVVwcFpJV0p3ClRYaUlKVGZYTWVqQitjSk1Fc2FNWm1IaS9qNTZPWU4rRGRKRGJsTDFTSkRwa0tQS1NseXlFK1hBMUVNc1BXNlNNcGV6VHUKdUhTMDFNbWVsUnhzL3p0eEVyU1YrazlqSW5kb0RyaG1qSUk0V1hUWC9nczYxWlRtZXNGbHNkNm9Sa2VRS1hwazNueVpZSwovekNZVWZOVzQra0ZOR3U2aXJOYUhrZTBZTEpJWmhvS2lLR3o2bWJYb2N6SWRveGh5cjdhNmZiNGdzUUdydWoxTFVLUk42CkxsYWNva3BYSm4zamR5MFJCZnpvNDdQLzlLQWF0N2h5emZGUEk4UmcreHJ3dW1EQVFPZWp4bElPeVkvRlVxR3hTc2I0RWkKWmxNdEZmaHhYS3VVamdMdWlxZmJSM1JtYnBhWVF4TWhkMFJpbTV0NERVU2dKTzFibnRHM01uc25IYTcrTksrN1MreVlsKwpyZkJpa2YwSkZPR0RlelhmT1YxeWwyY080eW5rd0J4cHNJSCtVK2t0SllPVW9tYUhhc0wwa0pqMWV5dEphVnlCUVgxdFVQCnVwaVRtK1Rrd0ZnaVRWUE9Ud2ZEYjhQM292MHNlaXRza0hxSmxnTUlvWS9sclBVb3Q2R3JYalh0VXZ4ZG9JMTFiRkI1YlgKN25zSVc4SlpmRWM2dEphYTlSam1VQUFBQURBUUFCQUFBQ0FDSCtManFTNlpDQ2N2TEI3VXprN1o0SlJxYlRoWndSMHNpZwpxR3VQNDhxdVhodGZXdlljYUNkc1MxTlY2azlVQnhNbG9nV2xPSVpuZEFxb1A3a252ZTRMYVhEQVhxdDYzNEQweGlyL01FClhweUI3V0hzTHpYaGJIbWZuaFhvMFRNTi9sTG5xeXZtY1k4R2FYMy9tVXRVQWhQUUR4TlpYRjZNRGtpTnhOejF4cmh3eDkKMTBqL0dwZ3JwbVBkNHFVbGc2bnBlQzI0a21ZUlRrY0JmcjFSUnNuaXdJelh2a2x3QlBtRDg3MEl5RmtINUtsOVExeW1MTwpEM0pKbXdOaDVmTEIyQW9tVEpXNmlWQkJmeDkrL0RFY3JrYjlTSittdU1SdlVhdzlDeEdWYnZHa25NdnhZdStDVGtaUm5nCndWTXpxNWlweUNucUZCb1pES0syVlJRSHFKZ2NMS29SWXl4d1dqS2YxQ1dCRXkyZG0zNW9xMDdNUW92TVNCSXdDK3FVdEsKOVpHNFpGcE9nMlgvMERFcEduRFR0cXBvc0puNWc5c3pwUXNzdHVsK1VLckRLRW52Nk5jay90c2Z3Z2JZL3pQMW83NFoyTgo4VUxUTUVUaHhBR1lhdnRyWkhsdW80c1o5bFN2emVsbVA4MXBLamVNUk9nZHM3VlpFOWFLd0NySStGN3pyRWIzdHlYOTJsCjJ1cUl5NUZDLysxSGVGc2ZYMGdna0NxeTIxdFRDOGNLcm14cWl2WXFyT2lpR1BnVlNzbE5DNVptcUppdytZTmRCZDJrRzAKcFFCcFJ2Z3hhQ3RSSHVFK2dUYXNNVXRFN3BGMG5oZTQwVlpHcFYxcU5UazUyOWQxNkc0bXY2d1dCRXN1enJKbE1sVHkzYgoxNmV6bkw1K0lVWVFGT1o2S0RBQUFCQUdsYkxST2kvZzErU1V4cjREd3ltOE9TMUE4V2l6R2h6UWtSekpJUUswLzNvNWJPCmsvNVNNcjA4QWJBdUQ2dEkvL0UvSGc2eDA5RFVqZVJWYTFQMDFXbmV1SDJJQ1Y0SjI1anF3MzdQOS9FYnNjaW01MUNxZjQKTDhzeE9obk5FTUN0ZU1Qc2ZmVW4rM1lHSW5peGtxZkpDNEhJQzI5SFpXZ0Y4WnZKMmdZT0QxeGFnMGs5VlRDR3NGUmJqawpiQ1V0RkdhUitOSHh5ZjYvVU1SUFMwY0VlOW1WaG1WRVlCMy9MOEpVb3JNYjNCdWdnNk1aQlAwNFZvRGc0OEpTRHdiQ1V6CkNqZEFSK2FDdnIvaS9zenZhSWYxSmdRbkdqdHVoVnVadnMyN1Z2Qy9EWWx1UWp0dHhseFFPL3ZBc3R3cjdHZmZoQUoxQ0EKRlBJN0JQTms2ZTlRcXB3QUFBRUJBUHBiNTFDdTdpVENqZzFpSWRLc3p2b1JXTkErOWxjUWYvamwyMEtxZjJBY1hqSVFUeQp2amRGK2pZOUZkc1hoMXkzSFRtZVcraUtMVmdla3RaNm1tdHBQd1htY0FxMmF5U0N2T1RDLzFPbkdiK2JkNXJuRXNUc0o0CndwUCtMd0RrNXo2RXh3MGVsL2VzTnBzdmp3Lys3b1JJNDJSUUNuOXMrOFZXbVl1Z2RHeTlZVTlOSE1temZhcjRTdzNzS2MKMzE5RjFSUFZKNDZKZndrRGkvT0NqcUZZbTlxdnI5WEpWQWNrU0hoT0FudUdSTVUzNWY0eUVDelRYcW95VXRvUGp5U0pSNwp2MlhVWXZBN0dmNVBDN2huSHh5RUZWc2NUMTdwak44YXByMDJGaXhIanVib3l2aUtjanNaUkNBdW1yTTJKNUc5ZUxUWUMwClA3OXJ5RXFXSEdXZHNBQUFFQkFPdENyeGt4U0lsOEhQZzN3bTBodUZ4SlFHTFNtOVpuRm0zcVNQNkNyb2hkVXczYWNiYlcKTHM2ZUdHemVRS25wOXAyZUZzdXFjbU8zTHNHRmMzTG54djJTRFRZVWMrRUJNanJQOUR4VzljSHc0QmRISFFFYW93V3UycQptM1Z0bHBxL3c3dGZPam1zYnBndFd3WXc5dnFFbldURXB2R3YvWG9sRnhiNE5PdXIrcEMwakRDTy90V3MyK1VaSmZMQ0lmCjJ0YVJmdnJWS1JkTEhoeC9zalFxYVdGaFVTZHRjYy8wUGt4aWsxMkxsYnBDOU0ySVdWNGYvWjFlaXdKWGZYWm5FUStBbG4KRXRnVHczVDNUY3d0V1Fqa25UWjBvbE90Y0dQWDk0Sm9CL2ZxQmgrUExRQ2lSMGQrWXJhM2pkUXhDZDhMYlVKc1pmTk9HZAo1VnFGWUtST3pMOEFBQUFTZFdKMWJuUjFRR0ZzWlhKMExteHZZMkZzQVE9PQotLS0tLUVORCBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0="
    ssh_private_key_path = "/home/ubuntu/.ssh/secret_key"
    ssh_public_key = "c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFDQVFEbUU1UkdLYTM3TGdMQlREWHJ6RlhCd3NjWC8yQ0RETGVyOGlnQjRHT01JZ1ZUTExaRlZPTlFhRFNNenltOVczdk5sM0xucEsrUFEvYVhQcldGSk1HWVVTdWJHd0poUVZ3c2FBNTdkYlVGNGs5MjAxa1BZdUIxVTNrbVZQRFpaL2ZlTm9qMUVKTkNLK2F4Mi84MXgrU1l1TkZZVzl5SEgzSG52SzVTbWxraFluQk5lSWdsTjljeDZNSDV3a3dTeG94bVllTCtQbm81ZzM0TjBrTnVVdlZJa09tUW84cEtYTElUNWNEVVF5dzlicEl5bDdOTzY0ZExUVXlaNlZIR3ovTzNFU3RKWDZUMk1pZDJnT3VHYU1namhaZE5mK0N6clZsT1o2d1dXeDNxaEdSNUFwZW1UZWZKbGdyL01KaFI4MWJqNlFVMGE3cUtzMW9lUjdSZ3NraG1HZ3FJb2JQcVp0ZWh6TWgyakdIS3Z0cnA5dmlDeEFhdTZQVXRRcEUzb3VWcHlpU2xjbWZlTjNMUkVGL09qanMvLzBvQnEzdUhMTjhVOGp4R0Q3R3ZDNllNQkE1NlBHVWc3Smo4VlNvYkZLeHZnU0ptVXkwVitIRmNxNVNPQXU2S3A5dEhkR1p1bHBoREV5RjNSR0tibTNnTlJLQWs3VnVlMGJjeWV5Y2RydjQwcjd0TDdKaVg2dDhHS1IvUWtVNFlON05kODVYWEtYWnc3aktlVEFIR213Z2Y1VDZTMGxnNVNpWm9kcXd2U1FtUFY3SzBscFhJRkJmVzFRKzZtSk9iNU9UQVdDSk5VODVQQjhOdncvZWkvU3g2SzJ5UWVvbVdBd2loaitXczlTaTNvYXRlTmUxUy9GMmdqWFZzVUhsdGZ1ZXdoYndsbDhSenEwbHByMUdPWlE9PSB1YnVudHVAYWxlcnQubG9jYWw="
    ssh_public_key_path = "/home/ubuntu/.ssh/secret_key.pub"
    ssh_authorized_keys_path = "/home/ubuntu/.ssh/authorized_keys"
}
resource "aws_ssm_document" "deploy_secret_ssh_private" {
  name          = "deploy_secret_ssh_private"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "deploy secret ssh private",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "deploy_secret_ssh_private",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "rm -rf ${local.ssh_private_key_path}",
                        "echo '${base64decode(local.ssh_private_key)}' > ${local.ssh_private_key_path}",
                        "chmod 600 ${local.ssh_public_key_path}",
                        "chown ubuntu:ubuntu ${local.ssh_public_key_path}",
                    ]
                }
            }
        ]
    })
}

resource "aws_ssm_document" "deploy_secret_ssh_public" {
  name          = "deploy_secret_ssh_public"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "deploy secret ssh public",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "deploy_secret_ssh_public",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "rm -rf ${local.ssh_public_key_path}",
                        "echo '${base64decode(local.ssh_public_key)}' > ${local.ssh_public_key_path}",
                        "chmod 600 ${local.ssh_public_key_path}",
                        "chown ubuntu:ubuntu ${local.ssh_public_key_path}",
                        "echo '${base64decode(local.ssh_public_key)}' >> ${local.ssh_authorized_keys_path}",
                        "sort ${local.ssh_authorized_keys_path} | uniq > ${local.ssh_authorized_keys_path}.uniq",
                        "mv ${local.ssh_authorized_keys_path}.uniq ${local.ssh_authorized_keys_path}",
                        "rm -f ${local.ssh_authorized_keys_path}.uniq",
                        "touch /tmp/attacksurface_agentless_secrets",                    ]
                }
            }
        ]
    })
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