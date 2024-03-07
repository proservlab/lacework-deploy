// Scope : MONITORED_SUBSCRIPTION
// Use	 : Enumerate Instances & Access Disks in monitored resource groups for snapshot creation

resource "azurerm_role_definition" "agentless_monitored_subscription" {
  count = var.global ? 1 : 0

  name  = replace("${var.prefix}-snapshot-${local.suffix}", "-", "_")
  scope = local.monitored_role_scopes[0]

  permissions {
    actions = [
      "Microsoft.Compute/disks/read",
      "Microsoft.Compute/disks/beginGetAccess/action",
      "Microsoft.Compute/virtualMachines/instanceView/read",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/snapshots/read",
      "Microsoft.Compute/snapshots/write",
      "Microsoft.Compute/snapshots/delete",
      "Microsoft.Compute/snapshots/beginGetAccess/action",
      "Microsoft.Compute/snapshots/endGetAccess/action",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
    ]
    not_actions = []
  }

  assignable_scopes = local.monitored_role_scopes
}

//-----------------------------------------------------------------------------------

// Scope : SCANNING_SUBSCRIPTION
// Use	 : Create & Delete resources in scanner subscription
// Role for Scanner Instances to interact with resources in Scanner subscription
resource "azurerm_role_definition" "agentless_scanning_subscription" {
  count = var.global ? 1 : 0

  name  = replace("${var.prefix}-scanner-${local.suffix}", "-", "_")
  scope = local.scanning_subscription_id

  permissions {
    actions = [
      "Microsoft.Authorization/*/read",
      "Microsoft.Compute/locations/*",
      "Microsoft.Compute/virtualMachines/*",
      "Microsoft.Compute/cloudServices/*",
      "Microsoft.Compute/disks/write",
      "Microsoft.Compute/disks/read",
      "Microsoft.Compute/disks/delete",
      "Microsoft.Network/locations/*",
      "Microsoft.Network/networkInterfaces/*",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Storage/storageAccounts/listKeys/action",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/*/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/*/assign/action",
      "Microsoft.Network/publicIPAddresses/join/action",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
    ]
    not_actions = []
  }

  assignable_scopes = [local.scanning_subscription_id]
}
