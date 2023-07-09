<a href="https://lacework.com"><img src="https://techally-content.s3-us-west-1.amazonaws.com/public-content/lacework_logo_full.png" width="600"></a>

# responder-reverse-shell

A Terraform Module to create an SSM document to wait for a reverse shell connection to be received via netcat on a specified attacker C2 host and port and respond with a specified bash payload over the established reverse shell on the target machine every 30-minutes.  See default values below.

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
| [aws_resourcegroups_group.exec_reverse_shell_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group) | resource |
| [aws_ssm_association.exec_reverse_shell_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ssm_document.exec_reverse_shell_attacker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployment"></a> [deployment](#input\_deployment) | unique deployment id | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | name of the environment | `string` | n/a | yes |
| <a name="input_listen_ip"></a> [listen\_ip](#input\_listen\_ip) | IP address of attacker | `string` | `"0.0.0.0"` | no |
| <a name="input_listen_port"></a> [listen\_port](#input\_listen\_port) | Port address of attacker | `number` | `4444` | no |
| <a name="input_payload"></a> [payload](#input\_payload) | The bash commands payload to execute when target machine connects | `string` | `"touch /tmp/pwned\n"` | no |
| <a name="input_resource_query_exec_reverse_shell_attacker"></a> [resource\_query\_exec\_reverse\_shell\_attacker](#input\_resource\_query\_exec\_reverse\_shell\_attacker) | JSON query to idenfity resources which will have lacework deployed | <pre>object({<br>      ResourceTypeFilters = list(string)<br>      TagFilters  = list(object({<br>        Key = string<br>        Values = list(string)<br>      }))<br>    })</pre> | <pre>{<br>  "ResourceTypeFilters": [<br>    "AWS::EC2::Instance"<br>  ],<br>  "TagFilters": [<br>    {<br>      "Key": "ssm_exec_reverse_shell_attacker",<br>      "Values": [<br>        "true"<br>      ]<br>    }<br>  ]<br>}</pre> | no |

## Outputs

No outputs.
