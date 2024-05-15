This example creates resources for the current subscription used by Azure Resource Manager. It's the bare bone example of single region single subscription deployment.

## Sample Code

### versions.tf
```hcl
terraform {
  required_version = ">= 0.13"

  required_providers {
    lacework = {
      source = "lacework/lacework"
    }
  }
}
```

### main.tf
```hcl
// Create resources including lacework cloud integration in one region
module "lacework_azure_agentless_scanning_subscription_us_west" {
  source = "lacework/agentless-scanning/azure"

  integration_level              = "SUBSCRIPTION"
  global                         = true
  create_log_analytics_workspace = true
  region                         = "West US"
  scanning_subscription_id       = "abcd-1234"
  tenant_id                      = "efgh-5678"
}
```
