## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.eks-windows-nodegroup-asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_eks_node_group.node_group_windows](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_launch_template.eks_windows_nodegroup_lt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [kubernetes_config_map.amazon_vpc_cni_windows](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map_v1_data.configmap](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [aws_ami.eks_optimized_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_ca_cert"></a> [cluster\_ca\_cert](#input\_cluster\_ca\_cert) | n/a | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | n/a | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | n/a | `string` | n/a | yes |
| <a name="input_cluster_node_role_arn"></a> [cluster\_node\_role\_arn](#input\_cluster\_node\_role\_arn) | n/a | `string` | n/a | yes |
| <a name="input_cluster_sg"></a> [cluster\_sg](#input\_cluster\_sg) | n/a | `string` | n/a | yes |
| <a name="input_cluster_subnet"></a> [cluster\_subnet](#input\_cluster\_subnet) | n/a | `any` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | n/a | `string` | `"1.24"` | no |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | unique deployment id | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | name of the environment | `string` | n/a | yes |

## Outputs

No outputs.
