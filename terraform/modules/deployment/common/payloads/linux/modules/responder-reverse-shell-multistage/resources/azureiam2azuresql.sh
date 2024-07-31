#!/bin/bash
SCRIPTNAME=azureiam2azuresql
LOGFILE=/tmp/$SCRIPTNAME.log
function log { 
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" && echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE 
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true


log "Downloading jq..."
if ! command -v jq; then curl -LJ -o /usr/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64 && chmod 755 /usr/bin/jq; fi

log "public ip: $(curl -s https://icanhazip.com)"

# azure cred setup
export AZURE_CREDS_PATH="./my.azureauth"
# export AZURE_CREDS_PATH="~/.azure/my.azureauth"
export AZURE_CLIENT_ID=$(jq -r '.clientId' $AZURE_CREDS_PATH)
export AZURE_CLIENT_SECRET=$(jq -r '.clientSecret' $AZURE_CREDS_PATH)
export AZURE_TENANT_ID=$(jq -r '.tenantId' $AZURE_CREDS_PATH)
export AZURE_SUBSCRIPTION_ID=$(jq -r '.subscriptionId' $AZURE_CREDS_PATH)
export IDENTITY_ENDPOINT="https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/token"
export HEADERS_FILE="/tmp/headers.txt"
# az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

# cloud enumeration
#scout azure --file-auth ~/.azure/my.azureauth --report-dir /$SCRIPTNAME/scout-report --no-browser 2>&1 | tee -a $LOGFILE

echo "Authenticating service principal..."
AUTH_RESULT=$(curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" \
"${IDENTITY_ENDPOINT}" \
-d "client_id=${AZURE_CLIENT_ID}" \
-d "grant_type=client_credentials" \
-d "resource=https://management.azure.com/" \
-d "client_secret=${AZURE_CLIENT_SECRET}")

cat <<EOF
AUTH_RESULT=$AUTH_RESULT
EOF

TOKEN=$(echo $AUTH_RESULT | jq -r '.access_token')

cat <<EOF
TOKEN=$TOKEN
EOF

echo "Listing resource groups..."
RESOURCE_GROUPS_RESULT=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourcegroups?api-version=2021-04-01")

cat <<EOF
RESOURCE_GROUPS_RESULT=$RESOURCE_GROUPS_RESULT
EOF

echo "Finding resource group name for database..."
RESOURCE_GROUP_NAME=$(echo $RESOURCE_GROUPS_RESULT | jq -r '.value[]| select(.name | startswith("resource-group-target")) | .name')
DEPLOYMENT_ID=$(echo $RESOURCE_GROUPS_RESULT | jq -r '.value[] | select(.name | startswith("resource-group-target")) | .tags.deployment')

cat <<EOF
RESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME
DEPLOYMENT_ID=$DEPLOYMENT_ID
EOF

echo "Listing flexible mysql servers..."
# List SQL Flexible Servers within the specified resource group (mysql) Microsoft.DBforMySQL
MYSQL_SERVERS=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DBforMySQL/flexibleServers?api-version=2021-05-01")

cat <<EOF
MYSQL_SERVERS=$MYSQL_SERVERS
EOF

echo "Getting sql server name..."
SERVER_NAME=$(echo $MYSQL_SERVERS | jq -r '.value[0].name')

cat <<EOF
SERVER_NAME=$SERVER_NAME
EOF

echo "Requesting a list of backups for $SERVER_NAME..."
BACKUPS=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DBforMySQL/flexibleServers/${SERVER_NAME}/backups?api-version=2023-10-01-preview")

cat <<EOF
BACKUPS=$BACKUPS
EOF

echo "Getting latest backup..."
BACKUP_NAME=$(echo $BACKUPS | jq -r '.value[-1].name')

echo "Creating backup..."
CURRENT_DATE=$(date +%Y%m%d%H%M%S)
NEW_BACKUP_NAME="mybackup-${CURRENT_DATE}"
RESULT=$(curl -s -D -X PUT -H "content-length: 0" -H "Authorization: Bearer $TOKEN" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DBforMySQL/flexibleServers/${SERVER_NAME}/backups/${NEW_BACKUP_NAME}?api-version=2023-10-01-preview")

echo "Result..."
cat <<EOF
RESULT=$RESULT
EOF

# Extract Operation Status URL from headers
OPERATION_STATUS_URL=$(grep -Fi Location "$HEADERS_FILE" | awk '{print $2}' | tr -d '\r')
echo "Operation status URL: $OPERATION_STATUS_URL"

exit

echo "Getting a list of storage accounts..."
RESULT=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/providers/Microsoft.Storage/storageAccounts?api-version=2023-05-01")

echo "Result..."
cat <<EOF
RESULT=$RESULT
EOF

echo "Finding db backup storage account..."
DB_BACKUP_STORAGE_ACCOUNT_NAME=$(echo $RESULT | jq -r '.value[] | select(.id | contains("dbbackuptarget")) | .name')
DB_BACKUP_STORAGE_ACCOUNT_ID=$(echo $RESULT | jq -r '.value[] | select(.id | contains("dbbackuptarget")) | .id')

cat <<EOF
DB_BACKUP_STORAGE_ACCOUNT_NAME=$DB_BACKUP_STORAGE_ACCOUNT_NAME
DB_BACKUP_STORAGE_ACCOUNT_ID=$DB_BACKUP_STORAGE_ACCOUNT_ID
EOF

EXPIRY_TIME=$(date -u -v+60M +"%Y-%m-%dT%H:%M:%S.0000000Z")
echo "Setting expiry time for 1 hour: $EXPIRY_TIME"

SAS_DATA="{\"canonicalizedResource\":\"/blob/${DB_BACKUP_STORAGE_ACCOUNT_NAME}/backup\",\"signedResource\":\"c\",\"signedPermission\":\"rcw\",\"signedProtocol\":\"https\",\"signedExpiry\":\"${EXPIRY_TIME}\"}"
RESULT=$(curl -s -X POST -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${DB_BACKUP_STORAGE_ACCOUNT_NAME}/listServiceSas/?api-version=2017-06-01"  -d ${SAS_DATA})

cat <<EOF
RESULT=$RESULT
EOF

SAS_TOKEN=$(echo $RESULT | jq -r '.serviceSasToken')
cat <<EOF
SAS_TOKEN=$SAS_TOKEN
EOF

echo "Building SAS URI..."
SAS_URI="https://${DB_BACKUP_STORAGE_ACCOUNT_NAME}.blob.core.windows.net/backup?${SAS_TOKEN}"
cat <<EOF
SAS_URI=$SAS_URI
EOF

echo "Building export data payload..."
EXPORT_DATA="{\"targetDetails\":{\"objectType\":\"FullBackupStoreDetails\",\"sasUriList\":[\"${SAS_URI}\"]},\"backupSettings\":{\"backupName\":\"${NEW_BACKUP_NAME}\"}}"
cat <<EOF
EXPORT_DATA=$EXPORT_DATA
EOF

echo "Requesting export..."
RESULT=$(curl -s -D ${HEADERS_FILE} -X POST -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DBforMySQL/flexibleServers/${SERVER_NAME}/backupAndExport?api-version=2023-10-01-preview" -d ${EXPORT_DATA})
cat <<EOF
RESULT=$RESULT
EOF

# Extract Operation Status URL from headers
OPERATION_STATUS_URL=$(grep -Fi Location "$HEADERS_FILE" | awk '{print $2}' | tr -d '\r')
echo "Operation status URL: $OPERATION_STATUS_URL"

exit

OPERATION_ID=fa1e8fa6-ea44-40a9-b6f2-cbf287317145
REQUEST_ID=fa1e8fa6-ea44-40a9-b6f2-cbf287317145
#curl -s -X GET -H "Authorization: Bearer ${TOKEN}" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DBforMySQL/flexibleServers/${SERVER_NAME}/operationResults/${OPERATION_ID}?api-version=2023-10-01-preview"
curl -s -X GET -H "Authorization: Bearer ${TOKEN}" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DBforMySQL/flexibleServers/${SERVER_NAME}/operationProgress/${OPERATION_ID}?api-version=2023-10-01-preview"

# Extract Operation Status URL from headers
OPERATION_STATUS_URL=$(grep -Fi Location "$HEADERS_FILE" | awk '{print $2}' | tr -d '\r')
echo "Operation status URL: $OPERATION_STATUS_URL"