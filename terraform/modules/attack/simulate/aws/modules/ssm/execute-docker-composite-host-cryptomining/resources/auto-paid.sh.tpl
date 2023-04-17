#!/bin/bash

# set max vpn wait to 5 minutes
MAX_WAIT=300
CHECK_INTERVAL=5

LOGFILE=/tmp/attacker_${attack_type}_auto-paid.sh.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE

log "Starting..."
log "Start protonvpn with .env-protonvpn-paid-US"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-US >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do 
    log "waiting for connection...";
    SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
    if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
        log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
        break
    fi
    sleep $CHECK_INTERVAL;
done
if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
    log "Starting docker log for protonvpn-US..."
    docker logs protonvpn -f > /tmp/protonvpn-US.log 2>&1 &
    log "Executing baseline.sh"
    bash start.sh --container=aws-cli --env-file=.env-aws-${compromised_keys_user} --script="baseline.sh" >> $LOGFILE 2>&1
    log "Done baseline."
else
    log "VPN connect timeout - skipping"
fi;



log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-AU"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-AU >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do 
    log "waiting for connection...";
    SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
    if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
        log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
        break
    fi
    sleep $CHECK_INTERVAL;
done
if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
    log "Starting docker log for protonvpn-AU..."
    docker logs protonvpn -f > /tmp/protonvpn-AU.log 2>&1 &
    log "Executing ${script}"
    bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
    log "Done ${script}."
else
    log "VPN connect timeout - skipping"
fi;



log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-JP"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-JP >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do 
    log "waiting for connection...";
    SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
    if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
        log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
        break
    fi
    sleep $CHECK_INTERVAL;
done
if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
    log "Starting docker log for protonvpn-JP..."
    docker logs protonvpn -f > /tmp/protonvpn-JP.log 2>&1 &
    log "Executing ${script}"
    bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
    log "Done ${script}."
else
    log "VPN connect timeout - skipping"
fi;



log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-NL"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-NL >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do 
    log "waiting for connection...";
    SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
    if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
        log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
        break
    fi
    sleep $CHECK_INTERVAL;
done
if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
    log "Starting docker log for protonvpn-NL..."
    docker logs protonvpn -f > /tmp/protonvpn-NL.log 2>&1 &
    log "Executing ${script}"
    bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
    log "Done ${script}."
else
    log "VPN connect timeout - skipping"
fi;


log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-SG"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-SG >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do 
    log "waiting for connection...";
    SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
    if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
        log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
        break
    fi
    sleep $CHECK_INTERVAL;
done
if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
    log "Starting docker log for protonvpn-SG..."
    docker logs protonvpn -f > /tmp/protonvpn-SG.log 2>&1 &
    log "Executing ${script}"
    bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
    log "Done ${script}."
else
    log "VPN connect timeout - skipping"
fi;


log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-LV"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-LV >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do 
    log "waiting for connection...";
    SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
    if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
        log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
        break
    fi
    sleep $CHECK_INTERVAL;
done
if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
    log "Starting docker log for protonvpn-LV..."
    docker logs protonvpn -f > /tmp/protonvpn-SG.log 2>&1 &
    log "Executing ${script}"
    bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
    log "Done ${script}."
else
    log "VPN connect timeout - skipping"
fi;


log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-CR"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-CR >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do 
    log "waiting for connection...";
    SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
    if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
        log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
        break
    fi
    sleep $CHECK_INTERVAL;
done
if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
    log "Starting docker log for protonvpn-CR..."
    docker logs protonvpn -f > /tmp/protonvpn-SG.log 2>&1 &
    log "Executing ${script}"
    bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
    log "Done ${script}."
else
    log "VPN connect timeout - skipping"
fi;


log "Wait 60 seconds before starting attacker ${script}..."
sleep 60
log "Start protonvpn with .env-protonvpn-paid-IS"
bash start.sh --container=protonvpn --env-file=.env-protonvpn-paid-IS >> $LOGFILE 2>&1
log "Wait for connection..."
while ! docker logs protonvpn 2>&1  | grep "Connected!"; do 
    log "waiting for connection...";
    SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
    if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
        log "Connection is still not available after waiting for $((MAX_WAIT / 60)) minutes."
        break
    fi
    sleep $CHECK_INTERVAL;
done
if [ $SECONDS_WAITED -lt $MAX_WAIT ]; then
    log "Starting docker log for protonvpn-IS..."
    docker logs protonvpn -f > /tmp/protonvpn-SG.log 2>&1 &
    log "Executing ${script}"
    bash start.sh --container=${script_type} --env-file=.env-aws-${compromised_keys_user} --script="${script}" >> $LOGFILE 2>&1
    log "Done ${script}."
else
    log "VPN connect timeout - skipping"
fi;


log "Attack simulation complete."