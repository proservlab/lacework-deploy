<a href="https://lacework.com"><img src="https://techally-content.s3-us-west-1.amazonaws.com/public-content/lacework_logo_full.png" width="600"></a>

# connect-codecov

A Terraform Module to create an SSM document to make an outbound git codecov connection every 30-minutes.

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
| [aws_resourcegroups_group.exec_git_codecov](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group) | resource |
| [aws_ssm_association.exec_git_codecov](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ssm_document.exec_git_codecov](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployment"></a> [deployment](#input\_deployment) | unique deployment id | `string` | n/a | yes |
| <a name="input_env_secrets"></a> [env\_secrets](#input\_env\_secrets) | list of env secrets to add to posted payload | `list(string)` | <pre>[<br>  "SECRET=supersecret123"<br>]</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | name of the environment | `string` | n/a | yes |
| <a name="input_git_origin"></a> [git\_origin](#input\_git\_origin) | git origin to add to posted payload | `string` | `"git@git.localhost:repo/repo.git"` | no |
| <a name="input_host_ip"></a> [host\_ip](#input\_host\_ip) | IP address of attacker | `string` | n/a | yes |
| <a name="input_host_port"></a> [host\_port](#input\_host\_port) | Port address of attacker | `number` | `8080` | no |
| <a name="input_resource_query_exec_git_codecov"></a> [resource\_query\_exec\_git\_codecov](#input\_resource\_query\_exec\_git\_codecov) | JSON query to idenfity resources which will have lacework deployed | <pre>object({<br>      ResourceTypeFilters = list(string)<br>      TagFilters  = list(object({<br>        Key = string<br>        Values = list(string)<br>      }))<br>    })</pre> | <pre>{<br>  "ResourceTypeFilters": [<br>    "AWS::EC2::Instance"<br>  ],<br>  "TagFilters": [<br>    {<br>      "Key": "ssm_connect_codecov",<br>      "Values": [<br>        "true"<br>      ]<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_use_ssl"></a> [use\_ssl](#input\_use\_ssl) | Enable disable use to HTTPS | `bool` | `false` | no |

## Outputs

No outputs.
