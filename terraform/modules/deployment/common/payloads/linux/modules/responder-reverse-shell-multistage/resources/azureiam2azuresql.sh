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
export AZURE_CLIENT_ID=$(jq -r '.clientId' ~/.azure/my.azureauth)
export AZURE_CLIENT_SECRET=$(jq -r '.clientSecret' ~/.azure/my.azureauth)
export AZURE_TENANT_ID=$(jq -r '.tenantId' ~/.azure/my.azureauth)
export AZURE_SUBSCRIPTION_ID=$(jq -r '.subscriptionId' ~/.azure/my.azureauth)
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

# cloud enumeration
scout azure --file-auth ~/.azure/my.azureauth --report-dir /$SCRIPTNAME/scout-report --no-browser 2>&1 | tee -a $LOGFILE 

# sql access - export and exfil
# get parameter store credentials
# auth to mysql and trigger backup? or can we use az cli?
# depending on destintation we maybe need to get the output from a storage account and then copy locally

az mysql flexible-server list
az keyvault list
