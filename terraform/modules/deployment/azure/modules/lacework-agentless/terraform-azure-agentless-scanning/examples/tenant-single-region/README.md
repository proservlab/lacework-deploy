# Single tenant Example

In this example we'll create resources to support scanning for a single location.


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
provider "lacework" {}

// Create global resources, includes lacework cloud integration.
// This will also create regional resources too.
module "lacework_azure_agentless_scanning_single_tenant" {
  source = "lacework/agentless-scanning/azure"

  global                         = true
  create_log_analytics_workspace = true
  integration_level              = "tenant"
  tags                           = { "lw-example-tf" : "true" }
  scanning_subscription_id       = "abcd-1234"
  tenant_id                      = "efgh-5678"
}
```
