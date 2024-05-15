#!/bin/bash

export SCRIPTNAME="test"
export LOCKFILE="/tmp/lacework_deploy_$SCRIPTNAME.lock"
export LOCKLOG=/tmp/lock_$SCRIPTNAME.log
export MAXLOG=2
truncate -s0 $LOCKLOG
# Initial lock is debug for lock handler
export LOGFILE=$LOCKLOG
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
if command -v yum && ! command -v ps; then
    yum update -y && yum install -y procps
fi
CURRENT_PROCESS=$(echo $$)
PROCESSES=$(pgrep -f "\| tee /tmp/payload_$SCRIPTNAME \| base64 -d \| gunzip")
PROCESS_NAMES=$(echo -n $PROCESSES | xargs --no-run-if-empty ps fp)
COUNT=$(pgrep -f "\| tee /tmp/payload_$SCRIPTNAME \| base64 -d \| gunzip" | wc -l)
# logs initially appended to current log - no log rotate before checking lock file
log "Lock pids: $PROCESSES"
log "Lock process names: $PROCESS_NAMES"
log "Lock process count: $COUNT"
if [ -e "$LOCKFILE" ] && [ $COUNT -gt 1 ]; then
    log "LOCKCHECK: Another instance of the script is already running. Exiting..."
    exit 1
elif [ -e "$LOCKFILE" ] && [ $COUNT -eq 1 ]; then
    log "LOCKCHECK: Lock file with no running process found - updating lock file time and starting process"
    touch "$LOCKFILE"
else
    log "LOCKCHECK: No lock file and no running process found - creating lock file"
    mkdir -p "$(dirname "$LOCKFILE")" && touch "$LOCKFILE"
fi
function cleanup {
    rm -f "$LOCKFILE"
}
trap cleanup EXIT INT TERM
trap cleanup SIGINT

# Update lofile after lock check
export LOGFILE=/tmp/lacework_deploy_$SCRIPTNAME.log

# Log rotate
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true

# Determine Package Manager
if command -v apt-get &>/dev/null; then
    export PACKAGE_MANAGER="apt-get"
    PACKAGES="wget jq"
elif command -v yum &>/dev/null; then
    export PACKAGE_MANAGER="yum"
    PACKAGES="wget jq"
else
    log "Neither apt-get nor yum found. Exiting..."
    exit 1
fi

# Wait for Package Manager
check_package_manager() {
    if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        # Return 0 (false) if a package manager process is found, indicating it's busy
        ! pgrep -f "apt-get (install|update|remove|upgrade)" && \
        ! pgrep -f "aptitude (install|update|remove|upgrade)" && \
        ! pgrep -f "dpkg (install|configure)"
    else
        # Similar logic for yum/rpm
        ! pgrep -f "yum (install|update|remove|upgrade)" && \
        ! pgrep -f "rpm (install|update|remove|upgrade)"
    fi
}

# export log function
export -f log

# Conditional Commands based on package manager
if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
log "Starting apt pre-task";

log "Done apt pre-task";
elif [ "$PACKAGE_MANAGER" == "yum" ]; then
log "Starting yum pre-task";

log "Done yum pre-task";
fi
if [ "" != "$PACKAGES" ]; then
    while true; do
        /bin/bash -c "$PACKAGE_MANAGER update && $PACKAGE_MANAGER install -y $PACKAGES" >> $LOGFILE 2>&1
        if [ $? -ne 0 ]; then
            log "Failed to install some_package using $PACKAGE_MANAGER - retry required"
            while ! check_package_manager; do
                RAND_WAIT=$(($RANDOM%(300-30+1)+30))
                log "Waiting for $PACKAGE_MANAGER to be available - sleeping $RAND_WAIT"
                sleep $RAND_WAIT
            done
        else
            break
        fi
    done
fi
if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
log "Starting apt post-task";

log "Done apt post-task";
elif [ "$PACKAGE_MANAGER" == "yum" ]; then
log "Starting yum post-task";

log "Done yum post-task";
fi

MAX_WAIT=60
CHECK_INTERVAL=60
log "starting delay: $MAX_WAIT seconds"
SECONDS_WAITED=0
while true; do 
    SECONDS_WAITED=$((SECONDS_WAITED + CHECK_INTERVAL))
    if [ $SECONDS_WAITED -ge $MAX_WAIT ]; then
        log "completed wait $((MAX_WAIT / 60)) minutes." && break
    fi
    sleep $CHECK_INTERVAL;
done
log "delay complete"

log "starting next stage after $SECONDS_WAITED seconds..."
log "starting execution of next stage payload..."
log "Starting my process..."
sleep 600
log "Process ended"
log "done next stage payload execution."

log "Done"