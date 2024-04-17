# Azure Cloud Tenant-Level for Multiple Regions

In this example we'll create resources to support scanning for multiple regions (US West, US East). 

Global resources are deployed to US West:
- Custom Roles and permissions
- Scanning Resource Group
- Key Vault 
- Storage Account

Regional resources are deployed to US West and US East
- Container App Job 

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
module "lacework_azure_agentless_scanning_tenant_us_west" {
  source = "lacework/agentless-scanning/azure"

  integration_level              = "TENANT"
  global                         = true
  create_log_analytics_workspace = true
  region                         = "West US"
  scanning_subscription_id       = "abcd-1234"
  tenant_id                      = "efgh-5678"
}

module "lacework_azure_agentless_scanning_single_tenant_us_east" {
  source = "lacework/agentless-scanning/azure"

  integration_level              = "TENANT"
  global                         = false
  create_log_analytics_workspace = true
  global_module_reference        = module.lacework_azure_agentless_scanning_tenant_us_west
  region                         = "East US"
  scanning_subscription_id       = "abcd-1234"
  tenant_id                      = "efgh-5678"
}
```
