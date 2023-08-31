#!/bin/bash

SCRIPTNAME="$(basename "$0")"
SHORT_NAME="${SCRIPTNAME%.*}"
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_DIR="$(basename $SCRIPT_PATH)"
VERSION="0.0.1"

#LOGFILE=/tmp/example.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    # echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
# truncate -s 0 $LOGFILE

export AWS_EXECUTION_ENV="${SHORT_NAME}-${SCRIPT_DIR}"

log "AWS_EXECUTION_ENV: ${AWS_EXECUTION_ENV}"
log "Initializing Terraform..."
terraform init -upgrade
log "Applying Terraform..."
terraform apply -auto-approve
log "Complete."
sleep 30
terraform destroy -auto-approve
