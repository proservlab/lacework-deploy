locals {
    ssh_private_key = "LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUNGd0FBQUFkemMyZ3RjbgpOaEFBQUFBd0VBQVFBQUFnRUF2djlTV2dyNDVmSlprTTdFTWZLN0J2eGQwY05yVlNjNzVvbHNvS2pMK1pxY1VvYXhRK2dxCjdPek8rZkEramY2SWszZVFaNUpLbko0WUsveCtOcWgrOW81cVdnY05oQ2FTYURKTnZMaHU5SVZML2hSWk0vMkZRQjFSRDEKUFRNMDFDOU1Db1NxRmhrcTJ6NjV5dXlNNlZBdmdXZG1ETUxiNkl4MFk1bnBDRUhmQ2JkS3RHa0pDSUNPYlkyM095NnptVgpjQnhSbDNnMFJmdVFVMW8rWFV3L3Y4R3o2a21TQ0hDWVFzdFlqNWRlTnAzdVpCeXdGNEhZeTVGOGxvMjdHbWQ5RWNaeDVYCndwUDBoUWlQdnZDQ1JaSWNLTHphbXNUMFZwZXd2N2hydnZlU1hSRGdleTh3OUdITVA1dGQ4RUdNSHVOQ2JySkVFcmJZeloKUisrZ1NaSE9ra1ZHaXczUTRUTVkrQ3ZlNE02Q1ByNy9KTnhJT09Ea0VGQWJ6aXNqdjhUQkpaT1VGVFhYM1M2SmNOKzBPeQpaaXhwRVVqbUV1MGRGV3BDMzJOZ0gvRzBUNll6VW84QW9lckVXRStwRnNnSGVBektPZ3NlOEFTczV6UWNrZnBMU3JZLzNtCnduMkdBa05HMHlGUGRTWG5POCtvclE4OStYL0xuOTUvUFpjYlVqU1pmcndLNWhTK0p1dzc3T0x4TWdNMHB1dGRYUXRFeDkKazhhN255azZoZW1EZk9XZVlGL2FJV1RSRUJhYk5JN3lHZVE5Y1NJK0lVZE5hYm9XMHd5QjNlN1FMbnJaS2t6cU1hRnBVcApPOEdGVFlBMm9mQzJ2NnB3UmJUSUFwQVhTTGovN1JXNlNIa0tsTyt4Qy9RbWN5cndSZ0lPNHNzVENJL3h4NVJhRi9LNm9nClVBQUFkSWt0cm56NUxhNTg4QUFBQUhjM05vTFhKellRQUFBZ0VBdnY5U1dncjQ1Zkpaa003RU1mSzdCdnhkMGNOclZTYzcKNW9sc29LakwrWnFjVW9heFErZ3E3T3pPK2ZBK2pmNklrM2VRWjVKS25KNFlLL3grTnFoKzlvNXFXZ2NOaENhU2FESk52TApodTlJVkwvaFJaTS8yRlFCMVJEMVBUTTAxQzlNQ29TcUZoa3EyejY1eXV5TTZWQXZnV2RtRE1MYjZJeDBZNW5wQ0VIZkNiCmRLdEdrSkNJQ09iWTIzT3k2em1WY0J4UmwzZzBSZnVRVTFvK1hVdy92OEd6NmttU0NIQ1lRc3RZajVkZU5wM3VaQnl3RjQKSFl5NUY4bG8yN0dtZDlFY1p4NVh3cFAwaFFpUHZ2Q0NSWkljS0x6YW1zVDBWcGV3djdocnZ2ZVNYUkRnZXk4dzlHSE1QNQp0ZDhFR01IdU5DYnJKRUVyYll6WlIrK2dTWkhPa2tWR2l3M1E0VE1ZK0N2ZTRNNkNQcjcvSk54SU9PRGtFRkFiemlzanY4ClRCSlpPVUZUWFgzUzZKY04rME95Wml4cEVVam1FdTBkRldwQzMyTmdIL0cwVDZZelVvOEFvZXJFV0UrcEZzZ0hlQXpLT2cKc2U4QVNzNXpRY2tmcExTclkvM213bjJHQWtORzB5RlBkU1huTzgrb3JRODkrWC9Mbjk1L1BaY2JValNaZnJ3SzVoUytKdQp3NzdPTHhNZ00wcHV0ZFhRdEV4OWs4YTdueWs2aGVtRGZPV2VZRi9hSVdUUkVCYWJOSTd5R2VROWNTSStJVWROYWJvVzB3CnlCM2U3UUxuclpLa3pxTWFGcFVwTzhHRlRZQTJvZkMydjZwd1JiVElBcEFYU0xqLzdSVzZTSGtLbE8reEMvUW1jeXJ3UmcKSU80c3NUQ0kveHg1UmFGL0s2b2dVQUFBQURBUUFCQUFBQ0FBSDBxZi9nS3dVVkZjMXVkTmZYSjhhVGVFeVk1ZTY1cnpBQQp1eXNXUGxLVXBQbXFTYys0VkhsQ2RSbHZKUCtBQk93ZzEwcWd2VUQ2WE9qLy9sY2ZtdFN0V09rcjRoM1FianJTR3kwaklICllnUDByU20xRmNDS3lZbDdoTFFqMjBvNS9QU3RCQ2EwK2U2eTYzWDVyTVlhamx1U2xzNGVwWG1MYzIvSGhTUUJ0R1lHQVAKdU9tbkcrSEF5VDdmbloxQ3VoWXo3YUZyU3B5clBNVFRENXBJOXNwcFZvMVptUnFzT0RZY05xb3ozMERUNnNRT21MNTRFNgpPTnVCWE54T3hMVzhrb3p5c1dRb1JEZ0tHOTZ6THZXQlJ2ZTg0d3hyZE84c2RKZ1E2QWgzb0QwK3B5RDk2Z3ZoTzJxVFVlClYxb2hpOVJXTm51Q2pia0ZEQSs1TE5KVUI3LzdZUnVyUElHU2YxUXhFUXo0R1dNUndURlJLR1V2b0RoNDJVQldTdjltMHoKLy9iTmhrcXlTSVZITWxqVmJkeU9QUlhweG11MnpKWFhDeVNPc2dScmdBUk5vMzIyc1libGJFd3k4cDV1Q1FqRjlBNXpFUwpMZDRtZUJ2VDBaVkRSNnRjbEJBOXFlenNpa2FNM2xzZEs1RHQyUXkrMStLTE1oWWRXQzNBYU5jZUtzS0xldEZUK2tOekp4ClRJWlBzQng5QzN6aS9KKzNhQndFNmN1OE43cFI0NFV0U213TU8vbXVQYThWdUVCZEpiMk4wL05Tc3dJQlptcUNiOFgzamEKaWJ0S252Um9adktnZkR6Z0FZNGRxckx2WGlYekQrbEFRRDdQd2FJaXZjME5VQWhUNUYydHBNZTQ1bGlwU0xiRTZDWW5hTgpZdnNORyszK2NkMXp1eDZwOEJBQUFCQVFDMzF4R3hRV1dSd2wyM3NPZ0hUbUQ2UXUwakoxcVJoUkIrdyt2VXh5WVdEREpIClVGOUpHajVJbXBac0U2MjJITzZ1NzdCbitORU83KzZEa0RFS2JxRjFRYWpxR1M0R0kxZWhvSWQyeTY1VHNRNEZTOVhvelMKNmpOcy9rODdGK3c3eUxrQTVjZkRzUDNKOFpNTFp4N0cxMC9YQkJHaVk1L0M1eGphTXF4Y2lmdlE0VHdmQks3TlhpTGZEYQpGMGo1eGxmSUhpR2R2VGxxSDFRTDc1YTl5Y3pZSytaMTJhSFc2d2xJWXJ5RHIzRVBCNm5KK2xDZDJSeXlZdytLMzBEVHNRClp3SFR5M09zSW9XeERyS2NNR2pCQnVublZPNmQ5SjZaUUcxWXlrKzVIU1FCeU5abVdwemNncld5TVRWUzFsMEZ3ZW1wcHQKTVhBc3g4SEhFOHBCUy9JK0FBQUJBUUQ2MUl1THhXN1Q2anhDSngxS1lXT0gwNGxxeHRwb2J1dXhVb1pMQTM5dHVucDhMcgo0UGZ6c3gyeFRNVGNYNlZDVDNtV3NteDBzMm9Fd0VUVHBFS0d6bE9DbWk1RU1xVXlTdEIraDdTQnNDR1JmMDFEaFBWTXFICnNLOHFPclVOcGhzeHloRUZtN1E1Z2t2SjBvQXpYOHY0OXF2Wm5ibkl5ci9XdS9scXVsVGcwQkxCZjRCRDRzV2hXQmxPb2UKNmhUZWhLWDZFajBBc3FvOWhyWm5qbmNJbU9ZODJHelhPL0F3SDF5TlZBdFMwZW0vOUdXbDhDVTM1MDk1SG9zc2RBNUZUQwpRUG1GQTdmZXNWQzJOZFBpSUw2cWhnNWR6eUhpL1lmNnZ4Z2Y0anRYcVpLRzljbXdkcHZzaEh0MnEyWFk2Y2pwR3JnZDR1Cjd6aDg5RlMxR1Y3cXRsQUFBQkFRREM3eFNXUmRYdjlHSlh1SjFqRlZKMnM1M05Vc3g3WVRlK2g0VElCQWxTVFNoUTZDNksKeHRyejZlc0E5Rnl2T2ppUlIrY25XSUJBQ1ZUY0Zodkp2OG5FNkVuNzgwajd1MXJmYVZBSUk0NmZud1VmRndCTVRSKzFpNgpDODMvSWU2SUUyaVRyMCtsdHcrTFRWOG5YRGs0RTBGeG1kUUJoS0t2TGRJTmhyL04yUFN6WFJpV2s1dmd2Y0c4QS9XdFdVCnp0b0piUzRIcnlWbi9iVWtQTVorWDZOTC9BNGlET2pDcjRBRW9lWEMvZmcwOHVWNDlWRUZLVHlsYjNOZUJFWmtEZno3WWIKN3Q0YVpydW1aYlFHc3JvZm5UNXpYNnhaOEtLN3gwVldmdUh0bytZd0RwcHRwSTR1YlN4cVd3WVQ1WWZhcDc5dmRCUnZNZgpLdWJPdnd0TmhNSWhBQUFBRW5WaWRXNTBkVUJoYkdWeWRDNXNiMk5oYkE9PQotLS0tLUVORCBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0="
    ssh_private_key_path = "/home/ubuntu/.ssh/secret_key"
    ssh_public_key = "c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFDQVFDKy8xSmFDdmpsOGxtUXpzUXg4cnNHL0YzUncydFZKenZtaVd5Z3FNdjVtcHhTaHJGRDZDcnM3TTc1OEQ2Ti9vaVRkNUJua2txY25oZ3IvSDQycUg3MmptcGFCdzJFSnBKb01rMjh1RzcwaFV2K0ZGa3ovWVZBSFZFUFU5TXpUVUwwd0toS29XR1NyYlBybks3SXpwVUMrQloyWU13dHZvakhSam1la0lRZDhKdDBxMGFRa0lnSTV0amJjN0xyT1pWd0hGR1hlRFJGKzVCVFdqNWRURCsvd2JQcVNaSUljSmhDeTFpUGwxNDJuZTVrSExBWGdkakxrWHlXamJzYVozMFJ4bkhsZkNrL1NGQ0krKzhJSkZraHdvdk5xYXhQUldsN0MvdUd1Kzk1SmRFT0I3THpEMFljdy9tMTN3UVl3ZTQwSnVza1FTdHRqTmxINzZCSmtjNlNSVWFMRGREaE14ajRLOTdnem9JK3Z2OGszRWc0NE9RUVVCdk9LeU8veE1FbGs1UVZOZGZkTG9sdzM3UTdKbUxHa1JTT1lTN1IwVmFrTGZZMkFmOGJSUHBqTlNqd0NoNnNSWVQ2a1d5QWQ0RE1vNkN4N3dCS3puTkJ5UitrdEt0ai9lYkNmWVlDUTBiVElVOTFKZWM3ejZpdER6MzVmOHVmM244OWx4dFNOSmwrdkFybUZMNG03RHZzNHZFeUF6U202MTFkQzBUSDJUeHJ1ZktUcUY2WU44NVo1Z1g5b2haTkVRRnBzMGp2SVo1RDF4SWo0aFIwMXB1aGJURElIZDd0QXVldGtxVE9veG9XbFNrN3dZVk5nRGFoOExhL3FuQkZ0TWdDa0JkSXVQL3RGYnBJZVFxVTc3RUw5Q1p6S3ZCR0FnN2l5eE1Jai9ISGxGb1g4cnFpQlE9PSB1YnVudHVAYWxlcnQubG9jYWw="
    ssh_public_key_path = "/home/ubuntu/.ssh/secret_key.pub"
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
                    ]
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