#!/bin/bash

LOGFILE=/tmp/attacker_${attack_type}_auto-paid.sh.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
check_apt() {
  pgrep -f "apt" || pgrep -f "dpkg"
}
while check_apt; do
  log "Waiting for apt to be available..."
  sleep 10
done

log "Starting..."
log "Start protonvpn with .env-protonvpn-paid-US"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-US >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done
log "Starting docker log for protonvpn-US..."
docker logs protonvpn -f > /tmp/protonvpn-US.log 2>&1 &
log "Executing baseline.sh"
bash start.sh --container=aws-cli --env-file=.env-aws-${compromised_keys_user} --script="baseline.sh" >> $LOGFILE 2>&1
log "Done baseline."


log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-AU"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-AU >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-AU..."
docker logs protonvpn -f > /tmp/protonvpn-AU.log 2>&1 &
log "Executing ${script}"
bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
log "Done ${script}."


log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-JP"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-JP >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-JP..."
docker logs protonvpn -f > /tmp/protonvpn-JP.log 2>&1 &
log "Executing ${script}"
bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
log "Done ${script}."


log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-NL"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-NL >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-NL..."
docker logs protonvpn -f > /tmp/protonvpn-NL.log 2>&1 &
log "Executing ${script}"
bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
log "Done ${script}."

log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-SG"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-SG >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do log "waiting for connection..."; sleep 10; done 
log "Starting docker log for protonvpn-SG..."
docker logs protonvpn -f > /tmp/protonvpn-SG.log 2>&1 &
log "Executing ${script}"
bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
log "Done ${script}."

log "Attack simulation complete."