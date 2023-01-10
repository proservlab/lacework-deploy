#!/bin/sh
# Minimal datacollector sidecar start script
#
# Environment Variables:
# LaceworkAccessToken="..."      (Required)
# LaceworkVerbose="true"           (Optional, will tail datacollector.log)

if [ -z "$LaceworkAccessToken" ]; then
  echo "Please set the LaceworkAccessToken environment variable"
  exit 1
fi

echo "Staging lacework directories and datacollector"
mkdir -p /var/log/lacework /var/lib/lacework/config
cp -p /var/lib/lacework-backup/*/datacollector-musl /var/lib/lacework/datacollector
chmod 755 /var/lib/lacework/datacollector

# Create config file
echo "Writing Lacework datacollector config file to /var/lib/lacework/config/config.json"
LW_CONFIG="{\"tokens\": {\"accesstoken\": \"${LaceworkAccessToken}\"}}"
echo $LW_CONFIG > /var/lib/lacework/config/config.json


# Optional debug logging
if [ "$LaceworkVerbose" = "true" ]; then
  echo "Debug mode: tailing /var/log/lacework/datacollector.log"
  touch /var/log/lacework/datacollector.log
  tail -f /var/log/lacework/datacollector.log &
fi


# Start datacollector
/var/lib/lacework/datacollector &
echo "Lacework datacollector started"

# Runas entrypoint
echo "Lacework sidecar running as ENTRYPOINT"
if [ "$LaceworkVerbose" = "true" ]; then
  echo "Executing: exec \"${@}\""
fi
exec "$@"