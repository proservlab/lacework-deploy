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

log "listener started."
log "done"