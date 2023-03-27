#!/bin/bash

LOGFILE=/tmp/attacker_${attack_type}_auto-free.sh.log
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
bash start.sh --container=aws-cli --env-file=.env-aws-${compromised_keys_user} --script="baseline.sh" >> $LOGFILE 2>&1
log "Done baseline."


log "Wait 1 hour before starting attacker ${script}..."
sleep 3600
log "Start protonvpn with .env-protonvpn-NL-FREE#148"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-NL-FREE#148 >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-NL-FREE#148..."
docker logs protonvpn -f > /tmp/protonvpn-NL-FREE#148.log 2>&1 &
log "Executing ${script}"
bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
log "Done ${script}."


log "Wait 1 hour before starting attacker ${script}..."
sleep 3600
log "Start protonvpn with .env-protonvpn-JP-FREE#3"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-JP-FREE#3 >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-JP-FREE#3..."
docker logs protonvpn -f > /tmp/protonvpn-JP-FREE#3.log 2>&1 &
log "Executing ${script}"
bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
log "Done ${script}."


log "Wait 1 hour before starting attacker ${script}..."
sleep 3600
log "Start protonvpn with .env-protonvpn-US-FREE#34"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-US-FREE#34 >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-US-FREE#34..."
docker logs protonvpn -f > /tmp/protonvpn-US-FREE#34.log 2>&1 &
log "Executing ${script}"
bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
log "Done ${script}."

log "Attack simulation complete."