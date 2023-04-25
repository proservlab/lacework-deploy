#!/bin/bash

# set max vpn wait to 5 minutes
MAX_WAIT=300
CHECK_INTERVAL=5

LOGFILE=/tmp/attacker_${attack_type}_auto-free.sh.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE

function wait_vpn_connection {
    SECONDS_WAITED=0
    while ! docker logs protonvpn 2>&1  | grep "Connected!"; do 
        log "waiting for connection...";
        SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
        if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
            log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
            break
        fi
        sleep $CHECK_INTERVAL;
    done
}
function execute_script {
    if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
        log "Starting docker log for $1..."
        docker logs protonvpn -f > /tmp/$1.log 2>&1 &
        log "Executing ${script}"
        bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
        log "Done ${script}."
    else
        log "VPN connect timeout - skipping"
    fi;
}

# baseline
log "Start protonvpn with .env-protonvpn-US"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-US >> $LOGFILE 2>&1
wait_vpn_connection
if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
    log "Starting docker log for protonvpn-US..."
    docker logs protonvpn -f > /tmp/protonvpn-US.log 2>&1 &
    log "Executing baseline.sh"
    bash start.sh --container=aws-cli --env-file=.env-aws-${compromised_keys_user} --script="baseline.sh" >> $LOGFILE 2>&1
    log "Done baseline."
else
    log "VPN connect timeout - skipping"
fi;

log "Wait ${attack_delay} seconds before starting attacker ${script}..."
sleep ${attack_delay}

SERVERS="NL-FREE#148 JP-FREE#3 US-FREE#34"
for SERVER in $SERVERS; do
    log "Wait 60 seconds before starting attacker ${script}..."
    sleep 60
    log "Start protonvpn with .env-protonvpn-$SERVER"
    bash start.sh --container=protonvpn --env-file=.env-protonvpn-$SERVER >> $LOGFILE 2>&1
    wait_vpn_connection
    execute_script "protonvpn-$SERVER"
done

log "Attack simulation complete."