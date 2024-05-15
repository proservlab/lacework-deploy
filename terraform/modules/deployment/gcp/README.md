## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.52.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.6.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.12.1 |
| <a name="requirement_lacework"></a> [lacework](#requirement\_lacework) | ~> 1.4 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.9.1 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gce"></a> [gce](#module\_gce) | ./modules/gce | n/a |
| <a name="module_gke"></a> [gke](#module\_gke) | ./modules/gke | n/a |
| <a name="module_id"></a> [id](#module\_id) | ../../context/deployment | n/a |
| <a name="module_lacework-osconfig-deployment-syscall-config"></a> [lacework-osconfig-deployment-syscall-config](#module\_lacework-osconfig-deployment-syscall-config) | ./modules/osconfig/deploy-lacework-syscall-config | n/a |
| <a name="module_osconfig-deploy-docker"></a> [osconfig-deploy-docker](#module\_osconfig-deploy-docker) | ./modules/osconfig/deploy-docker | n/a |
| <a name="module_osconfig-deploy-git"></a> [osconfig-deploy-git](#module\_osconfig-deploy-git) | ./modules/osconfig/deploy-git | n/a |
| <a name="module_osconfig-deploy-lacework-agent"></a> [osconfig-deploy-lacework-agent](#module\_osconfig-deploy-lacework-agent) | ./modules/osconfig/deploy-lacework-agent | n/a |
| <a name="module_workstation-external-ip"></a> [workstation-external-ip](#module\_workstation-external-ip) | ../general/workstation-external-ip | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | Schema defined in modules/context/infrastructure | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_config"></a> [config](#output\_config) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_infrastructure-config"></a> [infrastructure-config](#output\_infrastructure-config) | n/a |
| <a name="output_workstation_ip"></a> [workstation\_ip](#output\_workstation\_ip) | n/a |
