<a href="https://lacework.com"><img src="https://techally-content.s3-us-west-1.amazonaws.com/public-content/lacework_logo_full.png" width="600"></a>

# AWS Execute Modules

These modules are respondible for executing both target and attacker attacks on deployed infrastructure with attacksurface applied.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.6.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.12.1 |
| <a name="requirement_lacework"></a> [lacework](#requirement\_lacework) | ~> 1.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_aws.attacker"></a> [aws.attacker](#provider\_aws.attacker) | ~> 4.0 |
| <a name="provider_aws.target"></a> [aws.target](#provider\_aws.target) | ~> 4.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_id"></a> [id](#module\_id) | ../../../context/deployment | n/a |
| <a name="module_simulation-attacker-exec-docker-composite-cloud-cryptomining"></a> [simulation-attacker-exec-docker-composite-cloud-cryptomining](#module\_simulation-attacker-exec-docker-composite-cloud-cryptomining) | ./modules/ssm/execute-docker-composite-cloud-cryptomining | n/a |
| <a name="module_simulation-attacker-exec-docker-composite-cloud-ransomware"></a> [simulation-attacker-exec-docker-composite-cloud-ransomware](#module\_simulation-attacker-exec-docker-composite-cloud-ransomware) | ./modules/ssm/execute-docker-composite-cloud-ransomware | n/a |
| <a name="module_simulation-attacker-exec-docker-composite-compromised-credentials"></a> [simulation-attacker-exec-docker-composite-compromised-credentials](#module\_simulation-attacker-exec-docker-composite-compromised-credentials) | ./modules/ssm/execute-docker-composite-compromised-credentials | n/a |
| <a name="module_simulation-attacker-exec-docker-composite-defense-evasion"></a> [simulation-attacker-exec-docker-composite-defense-evasion](#module\_simulation-attacker-exec-docker-composite-defense-evasion) | ./modules/ssm/execute-docker-composite-defense-evasion | n/a |
| <a name="module_simulation-attacker-exec-docker-composite-host-cryptomining"></a> [simulation-attacker-exec-docker-composite-host-cryptomining](#module\_simulation-attacker-exec-docker-composite-host-cryptomining) | ./modules/ssm/execute-docker-composite-host-cryptomining | n/a |
| <a name="module_ssm-connect-badip"></a> [ssm-connect-badip](#module\_ssm-connect-badip) | ./modules/ssm/connect-badip | n/a |
| <a name="module_ssm-connect-codecov"></a> [ssm-connect-codecov](#module\_ssm-connect-codecov) | ./modules/ssm/connect-codecov | n/a |
| <a name="module_ssm-connect-nmap-port-scan"></a> [ssm-connect-nmap-port-scan](#module\_ssm-connect-nmap-port-scan) | ./modules/ssm/connect-nmap-port-scan | n/a |
| <a name="module_ssm-connect-oast-host"></a> [ssm-connect-oast-host](#module\_ssm-connect-oast-host) | ./modules/ssm/connect-oast-host | n/a |
| <a name="module_ssm-connect-reverse-shell"></a> [ssm-connect-reverse-shell](#module\_ssm-connect-reverse-shell) | ./modules/ssm/connect-reverse-shell | n/a |
| <a name="module_ssm-drop-malware-eicar"></a> [ssm-drop-malware-eicar](#module\_ssm-drop-malware-eicar) | ./modules/ssm/drop-malware-eicar | n/a |
| <a name="module_ssm-execute-docker-cpuminer"></a> [ssm-execute-docker-cpuminer](#module\_ssm-execute-docker-cpuminer) | ./modules/ssm/execute-docker-cpu-miner | n/a |
| <a name="module_ssm-execute-docker-log4shell-attack"></a> [ssm-execute-docker-log4shell-attack](#module\_ssm-execute-docker-log4shell-attack) | ./modules/ssm/execute-docker-log4shell-attack | n/a |
| <a name="module_ssm-execute-vuln-npm-app-attack"></a> [ssm-execute-vuln-npm-app-attack](#module\_ssm-execute-vuln-npm-app-attack) | ./modules/ssm/execute-vuln-npm-app-attack | n/a |
| <a name="module_ssm-listener-http-listener"></a> [ssm-listener-http-listener](#module\_ssm-listener-http-listener) | ./modules/ssm/listener-http-listener | n/a |
| <a name="module_ssm-listener-port-forward"></a> [ssm-listener-port-forward](#module\_ssm-listener-port-forward) | ./modules/ssm/listener-port-forward | n/a |
| <a name="module_ssm-responder-port-forward"></a> [ssm-responder-port-forward](#module\_ssm-responder-port-forward) | ./modules/ssm/responder-port-forward | n/a |
| <a name="module_ssm-responder-reverse-shell"></a> [ssm-responder-reverse-shell](#module\_ssm-responder-reverse-shell) | ./modules/ssm/responder-reverse-shell | n/a |
| <a name="module_workstation-external-ip"></a> [workstation-external-ip](#module\_workstation-external-ip) | ../general/workstation-external-ip | n/a |

## Resources

| Name | Type |
|------|------|
| [time_sleep.wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_instances.attacker_http_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.attacker_log4shell](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.attacker_port_forward](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.attacker_reverse_shell](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.attacker_vuln_npm_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.public_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.public_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.target_codecov](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.target_log4shell](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.target_port_forward](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.target_reverse_shell](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_instances.target_vuln_npm_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_security_groups.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_groups) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compromised_credentials"></a> [compromised\_credentials](#input\_compromised\_credentials) | n/a | `any` | n/a | yes |
| <a name="input_config"></a> [config](#input\_config) | Schema defined in modules/context/attack/simulate | `any` | n/a | yes |
| <a name="input_infrastructure"></a> [infrastructure](#input\_infrastructure) | n/a | <pre>object({<br>    config = any<br>    deployed_state = any<br>  })</pre> | n/a | yes |
| <a name="input_parent"></a> [parent](#input\_parent) | n/a | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_config"></a> [config](#output\_config) | n/a |
| <a name="output_default_provider"></a> [default\_provider](#output\_default\_provider) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
