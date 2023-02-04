#!/bin/bash

LOGFILE=/tmp/attacker_compromised_credentials_auto-paid.sh.log
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
docker logs protonvpn -f > /tmp/protonvpn-US.log 2>&1 &
log "Executing baseline.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-kees.kompromize@interlacelabs --script="baseline.sh" >> $LOGFILE 2>&1
log "Done baseline."


log "Wait 60 seconds before starting attacker discovery..."
sleep 60
log "Start protonvpn with .env-protonvpn-AU"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-AU >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-AU..."
docker logs protonvpn -f > /tmp/protonvpn-AU.log 2>&1 &
log "Executing discovery.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-kees.kompromize@interlacelabs --script="discovery.sh" >> $LOGFILE 2>&1
log "Done discovery."


log "Wait 60 seconds before starting attacker discovery..."
sleep 60
log "Start protonvpn with .env-protonvpn-JP"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-JP >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-JP..."
docker logs protonvpn -f > /tmp/protonvpn-JP.log 2>&1 &
log "Executing discovery.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-kees.kompromize@interlacelabs --script="discovery.sh" >> $LOGFILE 2>&1
log "Done discovery."


log "Wait 60 seconds before starting attacker discovery..."
sleep 60
log "Start protonvpn with .env-protonvpn-NL"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-NL >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-NL..."
docker logs protonvpn -f > /tmp/protonvpn-NL.log 2>&1 &
log "Executing discovery.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-kees.kompromize@interlacelabs --script="discovery.sh" >> $LOGFILE 2>&1
log "Done discovery."

log "Wait 60 seconds before starting attacker discovery..."
sleep 60
log "Start protonvpn with .env-protonvpn-SG"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-SG >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-SG..."
docker logs protonvpn -f > /tmp/protonvpn-SG.log 2>&1 &
log "Executing discovery.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-kees.kompromize@interlacelabs --script="discovery.sh" >> $LOGFILE 2>&1
log "Done discovery."

log "Attack simulation complete."