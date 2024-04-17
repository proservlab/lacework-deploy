This example shows you how to use custom vnet. Note it requires several steps:
1. `terraform init`
2. `terraform apply -target "azurerm_virtual_network.example"`
3. `terraform apply`

The reason of breaking the terraform operations into two targets is that 
Terraform needs to know at static time the value of 
`length(var.custom_network) > 0`, which is used in various `count` predicates.
However, in this example, the `custom_network` input variable can only be computed 
after `azurerm_virtual_network.example` is created. As such, Terraform won't be 
able to plan if we run `terraform plan/apply` to plan/create resources in one go.
Now we break it into step 2 and 3. Step 2 allows Terraform to create the vnet
resource first, and then Terraform will know that `length(custom_network) > 0` 
is true in step 3 at static time. 

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
provider "azurerm" {
  features {
  }
}

locals {
  region = "eastus"
}

/* create a resource group, a vnet, and a subnet within */
resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = local.region
}

/* Ensure the subnet allows egress traffic on port 443 or the scanner will break */
resource "azurerm_network_security_group" "lw" {
  depends_on          = [azurerm_resource_group.example]
  name                = "example-nsg"
  location            = local.region
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "Outbound_443"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_virtual_network" "example" {
  depends_on          = [azurerm_network_security_group.lw]
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = local.region
  resource_group_name = azurerm_resource_group.example.name

  subnet {
    name           = "example-subnet"
    address_prefix = "10.0.0.0/16"
    security_group = azurerm_network_security_group.lw.id
  }
}


/* create Lacework agentless integration within the custom setup */
module "lacework_azure_agentless_scanning_rg_and_vnet" {
  source = "lacework/agentless-scanning/azure"

  integration_level              = "SUBSCRIPTION"
  global                         = true
  custom_network                 = tolist(azurerm_virtual_network.example.subnet)[0].id
  create_log_analytics_workspace = true
  region                         = local.region
  scanning_subscription_id       = "abcd-1234"
  tenant_id                      = "efgh-5678"
}
```
