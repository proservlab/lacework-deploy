#!/bin/bash

DNS_DOMAIN=$1
DNS_IP=$2

function help {
	echo "Usage: $0 <DNS_DOMAIN> <DNS_IP>"
	exit 1
}

if [ -z $DNS_DOMAIN ]; then
   echo "Missing DNS_DOMAIN"
   help
fi	

if [ -z $DNS_IP ]; then
   echo "Missing DNS_IP"
   help
fi

echo "Starting check for $DNS_DOMAIN resolution to $DNS_IP..."

COUNTER=0
WAIT_SECS=900
while  [ $COUNTER -lt $WAIT_SECS ]; do
  DIG_RESULT=$(dig @8.8.8.8 +short $DNS_DOMAIN | tr -d '\n')
  echo "Checking if resolution of $DNS_DOMAIN [$DIG_RESULT] matches target address $DNS_IP..."
  if [ "$DIG_RESULT" == "$DNS_IP" ]; then
	exit 0
  else
	echo "No match. Sleep..." && sleep 5
  fi
  ((COUNTER++))
done

[ -z "$DNS_IP" ] && echo "Failed to resolve $DNS_DOMAIN to $DNS_IP"
exit 1
