<a href="https://lacework.com"><img src="https://techally-content.s3-us-west-1.amazonaws.com/public-content/lacework_logo_full.png" width="600"></a>

# execute-docker-composite-cloud-cryptomining

A Terraform Module to create an SSM document to orchestrate a set of steps related to a cloud cryptomining attack every 2-hours.

Procedure:
1. Placeholder
2. Placeholder

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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_resourcegroups_group.exec_docker_cloud_cryptomining_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group) | resource |
| [aws_ssm_association.exec_docker_cloud_cryptomining_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ssm_document.exec_docker_cloud_cryptomining_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compromised_credentials"></a> [compromised\_credentials](#input\_compromised\_credentials) | credentials to use in compromised keys attack | `any` | n/a | yes |
| <a name="input_compromised_keys_user"></a> [compromised\_keys\_user](#input\_compromised\_keys\_user) | n/a | `string` | `"claude.kripto@interlacelabs"` | no |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | unique deployment id | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | name of the environment | `string` | n/a | yes |
| <a name="input_ethermine_wallet"></a> [ethermine\_wallet](#input\_ethermine\_wallet) | ethermine wallet for cloud crypto | `string` | `""` | no |
| <a name="input_minergate_user"></a> [minergate\_user](#input\_minergate\_user) | minergate user for host crypto | `string` | `""` | no |
| <a name="input_nicehash_user"></a> [nicehash\_user](#input\_nicehash\_user) | nicehash user for host crypto | `string` | `""` | no |
| <a name="input_protonvpn_password"></a> [protonvpn\_password](#input\_protonvpn\_password) | protonvpn password | `string` | n/a | yes |
| <a name="input_protonvpn_protocol"></a> [protonvpn\_protocol](#input\_protonvpn\_protocol) | protonvpn protocol | `string` | `"udp"` | no |
| <a name="input_protonvpn_server"></a> [protonvpn\_server](#input\_protonvpn\_server) | protonvpn server (RANDOM, AU, CR, IS, JP, JP-FREE, LV, NL, NL-FREE, NZ, SG, SK, US, US-NJ, US-FREE,...); see https://api.protonmail.ch/vpn/logicals | `string` | `"RANDOM"` | no |
| <a name="input_protonvpn_tier"></a> [protonvpn\_tier](#input\_protonvpn\_tier) | protonvpn tier (0=free, 1=basic, 2=pro, 3=visionary) | `number` | `0` | no |
| <a name="input_protonvpn_user"></a> [protonvpn\_user](#input\_protonvpn\_user) | protonvpn user | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_resource_query_exec_docker_cloud_cryptomining_attacker"></a> [resource\_query\_exec\_docker\_cloud\_cryptomining\_attacker](#input\_resource\_query\_exec\_docker\_cloud\_cryptomining\_attacker) | JSON query to idenfity resources which will have lacework deployed | <pre>object({<br>      ResourceTypeFilters = list(string)<br>      TagFilters  = list(object({<br>        Key = string<br>        Values = list(string)<br>      }))<br>    })</pre> | <pre>{<br>  "ResourceTypeFilters": [<br>    "AWS::EC2::Instance"<br>  ],<br>  "TagFilters": [<br>    {<br>      "Key": "ssm_exec_docker_cloud_cryptomining_attacker",<br>      "Values": [<br>        "true"<br>      ]<br>    }<br>  ]<br>}</pre> | no |

## Outputs

No outputs.
