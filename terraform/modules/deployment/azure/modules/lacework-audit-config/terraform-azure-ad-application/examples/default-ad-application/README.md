# Default Creation of AD Application for Lacework

The following example shows how to deploy a new Azure AD application to be used in other modules to integrate Azure Tenant and Subscriptions with Lacework.

## Sample Code

```hcl
provider "azuread" {}

module "ad_application" {
  source  = "lacework/ad-application/azure"
  version = "~> 2.0"
}
```

For detailed information on integrating Lacework with Azure see [Azure Compliance & Activity Log Integrations - Terraform From Any Supported Host](https://support.lacework.com/hc/en-us/articles/360058966313-Azure-Compliance-Activity-Log-Integrations-Terraform-From-Any-Supported-Host)
