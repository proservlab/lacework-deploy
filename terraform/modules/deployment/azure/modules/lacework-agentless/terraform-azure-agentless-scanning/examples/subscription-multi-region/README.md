This example creates resources for multi-region subscription-level deployment.


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
// Create global resources, includes lacework cloud integration.
// This will also create regional resources too.
module "lacework_azure_agentless_scanning_subscription_us_west" {
  source = "lacework/agentless-scanning/azure"

  integration_level              = "SUBSCRIPTION"
  global                         = true
  create_log_analytics_workspace = true
  region                         = "West US"
  scanning_subscription_id       = "abcd-1234"
  tenant_id                      = "efgh-5678"
}

module "lacework_azure_agentless_scanning_subscription_us_east" {
  source = "lacework/agentless-scanning/azure"

  integration_level              = "SUBSCRIPTION"
  global                         = false
  create_log_analytics_workspace = true
  global_module_reference        = module.lacework_azure_agentless_scanning_subscription_us_west
  region                         = "East US"
  scanning_subscription_id       = "abcd-1234"
  tenant_id                      = "efgh-5678"
}
```
