#!/bin/bash

LOGFILE=/tmp/attacker_compromised_credentials_auto-free.sh.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE

log "Starting..."
log "Start protonvpn with .env-protonvpn-US"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-US >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done
log "Starting docker log for protonvpn-US..."
docker logs protonvpn -f > protonvpn-US.log 2>&1 &
log "Executing baseline.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-kees.kompromize@interlacelabs --script="baseline.sh" >> $LOGFILE 2>&1
log "Done baseline."


log "Wait 60 seconds before starting attacker discovery..."
sleep 60
log "Start protonvpn with .env-protonvpn-NL-FREE#148"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-NL-FREE#148 >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-NL-FREE#148..."
docker logs protonvpn -f > protonvpn-NL-FREE#148.log 2>&1 &
log "Executing discovery.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-kees.kompromize@interlacelabs --script="discovery.sh" >> $LOGFILE 2>&1
log "Done discovery."


log "Wait 60 seconds before starting attacker discovery..."
sleep 60
log "Start protonvpn with .env-protonvpn-JP-FREE#3"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-JP-FREE#3 >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-JP-FREE#3..."
docker logs protonvpn -f > protonvpn-JP-FREE#3.log 2>&1 &
log "Executing discovery.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-kees.kompromize@interlacelabs --script="discovery.sh" >> $LOGFILE 2>&1
log "Done discovery."


log "Wait 60 seconds before starting attacker discovery..."
sleep 60
log "Start protonvpn with .env-protonvpn-US-FREE#34"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-US-FREE#34 >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-US-FREE#34..."
docker logs protonvpn -f > protonvpn-US-FREE#34.log 2>&1 &
log "Executing discovery.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-kees.kompromize@interlacelabs --script="discovery.sh" >> $LOGFILE 2>&1
log "Done discovery."

log "Attack simulation complete."