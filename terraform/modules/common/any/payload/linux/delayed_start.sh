#!/usr/bin/env bash

# TEMPLATE INPUTS
# script_name: name of the script, which will be used for the log file (e.g. /tmp/<script_name>.log)
# log_rotation_count: total number of log files to keep
# apt_pre_tasks: shell commands to execute before install
# apt_packages: a list of apt packages to install
# apt_post_tasks: shell commands to execute after install
# yum_pre_tasks:  shell commands to execute before install
# yum_packages: a list of yum packages to install
# yum_post_tasks: shell commands to execute after install
# script_delay_secs: total number of seconds to wait before starting the next stage
# next_stage_payload: shell commands to execute after delay

export LOCKFILE="/tmp/lacework_deploy_${config["script_name"]}.lock"
if [ -e "$LOCKFILE" ]; then
    echo "Another instance of the script is already running. Exiting..."
    exit 1
else
    mkdir -p "$(dirname "$LOCKFILE")" && touch "$LOCKFILE"
fi
function cleanup {
    rm -f "$LOCKFILE"
}
trap cleanup EXIT INT TERM
trap cleanup SIGINT

export SCRIPTNAME="${config["script_name"]}"
export LOGFILE=/tmp/lacework_deploy_$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=${config["log_rotation_count"]}
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true

# Determine Package Manager
if command -v apt-get &>/dev/null; then
    export PACKAGE_MANAGER="apt-get"
    PACKAGES="${config["apt_packages"]}"
elif command -v yum &>/dev/null; then
    export PACKAGE_MANAGER="yum"
    PACKAGES="${config["yum_packages"]}"
else
    log "Neither apt-get nor yum found. Exiting..."
    exit 1
fi

# Wait for Package Manager
check_package_manager() {
    if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        # Using regex to match specific apt operations
        pgrep -f "apt-get (install|update|remove|upgrade)" || \
        pgrep -f "aptitude (install|update|remove|upgrade)" || \
        pgrep -f "dpkg (install|configure)"
    else
        # Check for yum or rpm processes with specific operations
        pgrep -f "yum (install|update|remove|upgrade)" || \
        pgrep -f "rpm (install|update|remove|upgrade)"
    fi
}
while check_package_manager; do
    log "Waiting for $PACKAGE_MANAGER to be available..."
    sleep 10
done

# export log function
export -f log

# Conditional Commands based on package manager
if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
log "Starting apt pre-task";
${config["apt_pre_tasks"]}
log "Done apt pre-task";
elif [ "$PACKAGE_MANAGER" == "yum" ]; then
log "Starting yum pre-task";
${config["yum_pre_tasks"]}
log "Done yum pre-task";
fi
if [ "" != "$PACKAGES" ]; then
    sudo /bin/bash -c "$PACKAGE_MANAGER update && $PACKAGE_MANAGER install -y $PACKAGES" >> $LOGFILE 2>&1
    if [ $? -ne 0 ]; then
        log "Failed to install some_package using $PACKAGE_MANAGER"
        exit 1
    fi
fi
if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
log "Starting apt post-task";
${config["apt_post_tasks"]}
log "Done apt post-task";
elif [ "$PACKAGE_MANAGER" == "yum" ]; then
log "Starting yum post-task";
${config["yum_post_tasks"]}
log "Done yum post-task";
fi

MAX_WAIT=${config["script_delay_secs"]}
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
${config["next_stage_payload"]}
log "done next stage payload execution."

log "Done"