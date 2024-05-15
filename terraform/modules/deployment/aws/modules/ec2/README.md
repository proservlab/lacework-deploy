## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_amis"></a> [amis](#module\_amis) | ./amis | n/a |
| <a name="module_default-ssm-tags"></a> [default-ssm-tags](#module\_default-ssm-tags) | ../../../../context/tags | n/a |
| <a name="module_instances"></a> [instances](#module\_instances) | ./instance | n/a |
| <a name="module_ssm_app_profile"></a> [ssm\_app\_profile](#module\_ssm\_app\_profile) | ./ssm-profile | n/a |
| <a name="module_ssm_profile"></a> [ssm\_profile](#module\_ssm\_profile) | ./ssm-profile | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./vpc | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployment"></a> [deployment](#input\_deployment) | unique deployment id | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | name of the environment | `string` | n/a | yes |
| <a name="input_instances"></a> [instances](#input\_instances) | n/a | <pre>list(<br>    object({<br>      name                            = string<br>      public                          = bool<br>      role                            = string<br>      instance_type                   = string<br>      ami_name                        = string<br>      tags                            = map(any)<br>      user_data                       = string<br>      user_data_base64                = string<br>    })<br>  )</pre> | <pre>[<br>  {<br>    "ami_name": "ubuntu_focal",<br>    "instance_type": "t2.micro",<br>    "name": "ec2-private-1",<br>    "public": false,<br>    "role": "default",<br>    "tags": {},<br>    "user_data": null,<br>    "user_data_base64": null<br>  }<br>]</pre> | no |
| <a name="input_private_app_egress_rules"></a> [private\_app\_egress\_rules](#input\_private\_app\_egress\_rules) | n/a | `list(map(any))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "description": "allow all outbound",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_private_app_ingress_rules"></a> [private\_app\_ingress\_rules](#input\_private\_app\_ingress\_rules) | n/a | `list(map(any))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "description": "allow ssh inbound",<br>    "from_port": 22,<br>    "protocol": "tcp",<br>    "to_port": 22<br>  }<br>]</pre> | no |
| <a name="input_private_app_nat_subnet"></a> [private\_app\_nat\_subnet](#input\_private\_app\_nat\_subnet) | private app nat subnet | `string` | `"172.17.10.0/24"` | no |
| <a name="input_private_app_network"></a> [private\_app\_network](#input\_private\_app\_network) | private network | `string` | `"172.17.0.0/16"` | no |
| <a name="input_private_app_subnet"></a> [private\_app\_subnet](#input\_private\_app\_subnet) | private subnet | `string` | `"172.17.100.0/24"` | no |
| <a name="input_private_egress_rules"></a> [private\_egress\_rules](#input\_private\_egress\_rules) | n/a | `list(map(any))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "description": "allow all outbound",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_private_ingress_rules"></a> [private\_ingress\_rules](#input\_private\_ingress\_rules) | n/a | `list(map(any))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "description": "allow ssh inbound",<br>    "from_port": 22,<br>    "protocol": "tcp",<br>    "to_port": 22<br>  }<br>]</pre> | no |
| <a name="input_private_nat_subnet"></a> [private\_nat\_subnet](#input\_private\_nat\_subnet) | private nat subnet | `string` | `"172.16.10.0/24"` | no |
| <a name="input_private_network"></a> [private\_network](#input\_private\_network) | private network | `string` | `"172.16.0.0/16"` | no |
| <a name="input_private_subnet"></a> [private\_subnet](#input\_private\_subnet) | private subnet | `string` | `"172.16.100.0/24"` | no |
| <a name="input_public_app_egress_rules"></a> [public\_app\_egress\_rules](#input\_public\_app\_egress\_rules) | n/a | `list(map(any))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "description": "allow all outbound",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_public_app_ingress_rules"></a> [public\_app\_ingress\_rules](#input\_public\_app\_ingress\_rules) | n/a | `list(map(any))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "description": "allow ssh inbound",<br>    "from_port": 22,<br>    "protocol": "tcp",<br>    "to_port": 22<br>  }<br>]</pre> | no |
| <a name="input_public_app_network"></a> [public\_app\_network](#input\_public\_app\_network) | public app network | `string` | `"172.19.0.0/16"` | no |
| <a name="input_public_app_subnet"></a> [public\_app\_subnet](#input\_public\_app\_subnet) | public subnet | `string` | `"172.19.0.0/24"` | no |
| <a name="input_public_egress_rules"></a> [public\_egress\_rules](#input\_public\_egress\_rules) | n/a | `list(map(any))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "description": "allow all outbound",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_public_ingress_rules"></a> [public\_ingress\_rules](#input\_public\_ingress\_rules) | n/a | `list(map(any))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "description": "allow ssh inbound",<br>    "from_port": 22,<br>    "protocol": "tcp",<br>    "to_port": 22<br>  }<br>]</pre> | no |
| <a name="input_public_network"></a> [public\_network](#input\_public\_network) | public network | `string` | `"172.18.0.0/16"` | no |
| <a name="input_public_subnet"></a> [public\_subnet](#input\_public\_subnet) | public subnet | `string` | `"172.18.0.0/24"` | no |
| <a name="input_trust_security_group"></a> [trust\_security\_group](#input\_trust\_security\_group) | Enable endpoints within the security group to communicate on all ports and protocols. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_instance_app_role"></a> [ec2\_instance\_app\_role](#output\_ec2\_instance\_app\_role) | n/a |
| <a name="output_ec2_instance_role"></a> [ec2\_instance\_role](#output\_ec2\_instance\_role) | n/a |
| <a name="output_instances"></a> [instances](#output\_instances) | n/a |
| <a name="output_private_app_network"></a> [private\_app\_network](#output\_private\_app\_network) | n/a |
| <a name="output_private_app_sg"></a> [private\_app\_sg](#output\_private\_app\_sg) | n/a |
| <a name="output_private_app_vpc"></a> [private\_app\_vpc](#output\_private\_app\_vpc) | n/a |
| <a name="output_private_network"></a> [private\_network](#output\_private\_network) | n/a |
| <a name="output_private_sg"></a> [private\_sg](#output\_private\_sg) | n/a |
| <a name="output_private_vpc"></a> [private\_vpc](#output\_private\_vpc) | n/a |
| <a name="output_public_app_igw"></a> [public\_app\_igw](#output\_public\_app\_igw) | n/a |
| <a name="output_public_app_network"></a> [public\_app\_network](#output\_public\_app\_network) | n/a |
| <a name="output_public_app_sg"></a> [public\_app\_sg](#output\_public\_app\_sg) | n/a |
| <a name="output_public_app_vpc"></a> [public\_app\_vpc](#output\_public\_app\_vpc) | n/a |
| <a name="output_public_igw"></a> [public\_igw](#output\_public\_igw) | n/a |
| <a name="output_public_network"></a> [public\_network](#output\_public\_network) | n/a |
| <a name="output_public_sg"></a> [public\_sg](#output\_public\_sg) | n/a |
| <a name="output_public_vpc"></a> [public\_vpc](#output\_public\_vpc) | n/a |
