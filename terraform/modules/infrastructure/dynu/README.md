## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dns-records"></a> [dns-records](#module\_dns-records) | ./modules/dns_records | n/a |
| <a name="module_id"></a> [id](#module\_id) | ../../context/deployment | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | Schema defined in modules/context/infrastructure | `any` | n/a | yes |
| <a name="input_dynu_api_key"></a> [dynu\_api\_token](#input\_dynu\_api\_token) | n/a | `string` | n/a | yes |
| <a name="input_dynu_dns_domain"></a> [dynu\_dns\_domain](#input\_dynu\_dns\_domain) | n/a | `string` | n/a | yes |
| <a name="input_parent"></a> [parent](#input\_parent) | n/a | `string` | `null` | no |
| <a name="input_records"></a> [records](#input\_records) | n/a | <pre>list(object({<br>        recordType = string<br>        recordName = string<br>        recordHostName = string<br>        recordValue = string<br>    }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_records"></a> [records](#output\_records) | n/a |
