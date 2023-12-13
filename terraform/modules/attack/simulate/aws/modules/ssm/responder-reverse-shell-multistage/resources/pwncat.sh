LOCKFILE="/tmp/pwncat_session.lock"

if [ -e "$LOCKFILE" ] && screen -ls | grep -q "pwncat" ]; then
    echo "Another instance of the script is already running. Exiting..."
    exit 1
elif ! screen -ls | grep -q "pwncat"; then
    echo "Screen session doesn't exist but lock file present - cleanup requied"
    rm -f $LOCKFILE
fi
function cleanup {
    rm -f "$LOCKFILE"
}

LOGFILE=/tmp/setup_pwncat.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=4
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
check_apt() {
    pgrep -f "apt" || pgrep -f "dpkg"
}
while check_apt; do
    log "Waiting for apt to be available..."
    sleep 10
done
PWNCAT_LOG="/tmp/pwncat.log"
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$PWNCAT_LOG."{$i,$((i+1))} 2>/dev/null || true; done
mv $PWNCAT_LOG "$PWNCAT_LOG.1" 2>/dev/null || true
log "starting background process via screen..."
screen -S pwncat -X quit
nohup /bin/bash -c "screen -d -L -Logfile $PWNCAT_LOG -S pwncat -m python3.9 listener.py --port ${listen_port}" >/dev/null 2>&1 &
screen -S pwncat -X colon "logfile flush 0^M"
log "Checking for listener..."
TIMEOUT=1800
START_TIME=$(date +%s)
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    if grep "listener created" $PWNCAT_LOG; then
        log "Found listener created log in $PWNCAT_LOG - checking for port response"
        while ! nc -z -w 5 -vv 127.0.0.1 ${listen_port} > /dev/null; do
            log "failed check - waiting for pwncat port response";
            sleep 30;
        done;
        break
    fi
    if [ $ELAPSED_TIME -gt $TIMEOUT ]; then
        log "Failed to find listener created log for pwncat - timeout after $TIMEOUT seconds"
        exit 1
    fi
done
log "listener started."
log "starting sleep for 90 minutes - blocking new tasks while accepting connections"
sleep 5400
log "sleep complete - exiting to allow next task run to fire"
log "done"