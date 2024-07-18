# Metdata

This is captured for future readers looking to understand the credentials compromise steps when using compute identity. In azure when a compute instance is assigned both a system identity (which is required when enabling SSH from Az CloudShell) and a user managed identity (much like an instance role in AWS) the default identity provided by the metadata service is the system identity. 

In order to move from the system identity to the user managed identity it is necessary to find or know the name of the user managed identity on the machine. There are various ways to provide this which allow the system identity to _know_ this value (e.g. vault, tag). 

Once the resource name is discovered for the user managed identity the next step is to obtain unique clientId (also known as the applicationId) for that identity. To do this the system managed identity either needs to have this provided in the methods above or it needs permission to read from the azure api to obtain this value. The following role assignment is an example of how to allow a system identity to read the properties of a single user managed identity:

```
{
    "id": "/subscriptions/d2c2a29c-caa1-466b-ae80-ded44dd4088c/providers/Microsoft.Authorization/roleDefinitions/0c1d94b5-5f82-b373-7ee2-bea8e70f241d",
    "properties": {
        "roleName": "system-identity-role-for-user-managed-identity-lookup",
        "description": "Custom role to read specific user-assigned identities",
        "assignableScopes": [
            "/subscriptions/d2c2a29c-caa1-466b-ae80-ded44dd4088c/resourceGroups/resource-group-target-38e2cd2f/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{RESOURCE NAME FOR THE IDENTITY}"
        ],
        "permissions": [
            {
                "actions": [
                    "Microsoft.ManagedIdentity/userAssignedIdentities/read"
                ],
                "notActions": [],
                "dataActions": [],
                "notDataActions": []
            }
        ]
    }
}
```

The following shell script is an example of this system to user managed identity path using the metadata service and az api:
```
# get subscription and resource group from metadata
METADATA=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01")
RESOURCE_GROUP_NAME=$(echo $METADATA | jq -r '.compute.resourceGroupName')
SUBSCRIPTION_ID=$(echo $METADATA | jq -r '.compute.subscriptionId')

# Assumes role tag is set to the user managed identity for the machine
USER_MANAGED_IDENTITY_NAME=$(echo $METADATA | jq -r '.compute.tagsList[] | select(.name=="access-role") | .value')


# Get the access token (if user and system are assigned system is returned by default)
TOKEN=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" | jq -r '.access_token')

# Get the user managed identity by name
USER_MANAGED_IDENTITY=$(curl -X GET -H "Authorization: Bearer $TOKEN" "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${USER_MANAGED_IDENTITY_NAME}?api-version=2023-01-31")

CLIENT_ID=$(echo $USER_MANAGED_IDENTITY | jq -r '.properties.clientId')

# Get the access token for a client_id
TOKEN=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/&client_id=$CLIENT_ID" | jq -r '.access_token')

# List SQL Flexible Servers within the specified resource group (postgresql)
curl -X GET -H "Authorization: Bearer $TOKEN" "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DBforPostgreSQL/flexibleServers?api-version=2021-06-01"

# List SQL Flexible Servers within the specified resource group (mysql) Microsoft.DBforMySQL
curl -X GET -H "Authorization: Bearer $TOKEN" "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DBforMySQL/flexibleServers?api-version=2021-05-01"
```