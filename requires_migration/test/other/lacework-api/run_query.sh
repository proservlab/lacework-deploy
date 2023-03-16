#!/bin/bash

SCRIPTNAME=$(basename "$0")
ACCOUNT=qa12ro
DOMAIN=qa12.qa12.corp

help () {
cat << EOF
usage: ${SCRIPTNAME} <PATH TO QUERY FILE>

EOF
     exit 1;
}

cleanup () {
    rm -f "${TMP_FILE}" > /dev/null 2>&1
}

if [ -z "$1" ]; then
    echo "Missing required query arg"
    help
elif [[ ! -f "$1" ]]; then
    echo "Query file not found: $1"
    help
else
    QUERY_FILE="$1"
fi

# generate a temporary access token using lacework cli
ACCESS_TOKEN=$(lacework --profile=${ACCOUNT} access-token)

# create temp file
TMP_FILE=$(mktemp -q /tmp/query.XXXXXX)

# read json query
QUERY=$(cat ${QUERY_FILE})

echo "Running query: "
jq . ${QUERY_FILE}

# query lacework api
echo "Executing query..."
curl -s -X POST \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -d "${QUERY}" \
    "https://${DOMAIN}.lacework.net/api/v2/Vulnerabilities/Hosts/search" \
    -o "${TMP_FILE}"
cat ${TMP_FILE}
if [[ -f "${TMP_FILE}" ]]; then
    jq . "${TMP_FILE}"
else
    echo "No query results returned"
    cleanup
    exit 1
fi


exit 
