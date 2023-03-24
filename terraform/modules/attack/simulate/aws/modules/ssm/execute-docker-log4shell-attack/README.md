<a href="https://lacework.com"><img src="https://techally-content.s3-us-west-1.amazonaws.com/public-content/lacework_logo_full.png" width="600"></a>

# execute-docker-log4shell-attack

A Terraform Module to create an SSM document to exploit log4shell on a specified target host and port, and subsequently execute a reverse shell outbound to a specified attacker host and LDAP port every 30-minutes.  Default values can be found below.

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
| [aws_resourcegroups_group.exec_docker_log4shell_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group) | resource |
| [aws_ssm_association.exec_docker_log4shell_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ssm_document.exec_docker_log4shell_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attacker_http_port"></a> [attacker\_http\_port](#input\_attacker\_http\_port) | listening port for webserver in container | `number` | `8088` | no |
| <a name="input_attacker_ip"></a> [attacker\_ip](#input\_attacker\_ip) | attacker ip | `string` | n/a | yes |
| <a name="input_attacker_ldap_port"></a> [attacker\_ldap\_port](#input\_attacker\_ldap\_port) | listening port for ldap in container | `number` | `1389` | no |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | unique deployment id | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | name of the environment | `string` | n/a | yes |
| <a name="input_payload"></a> [payload](#input\_payload) | bash payload to execute | `string` | `"touch /tmp/log4shell_pwned\n"` | no |
| <a name="input_resource_query_exec_docker_log4shell_attacker"></a> [resource\_query\_exec\_docker\_log4shell\_attacker](#input\_resource\_query\_exec\_docker\_log4shell\_attacker) | JSON query to idenfity resources which will have lacework deployed | <pre>object({<br>      ResourceTypeFilters = list(string)<br>      TagFilters  = list(object({<br>        Key = string<br>        Values = list(string)<br>      }))<br>    })</pre> | <pre>{<br>  "ResourceTypeFilters": [<br>    "AWS::EC2::Instance"<br>  ],<br>  "TagFilters": [<br>    {<br>      "Key": "ssm_exec_docker_log4shell_attacker",<br>      "Values": [<br>        "true"<br>      ]<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_target_ip"></a> [target\_ip](#input\_target\_ip) | target ip | `string` | n/a | yes |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | target port | `number` | n/a | yes |

## Outputs

No outputs.
