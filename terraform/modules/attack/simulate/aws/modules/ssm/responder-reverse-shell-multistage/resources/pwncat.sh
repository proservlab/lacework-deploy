LOGFILE=/tmp/setup_pwncat.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE
check_apt() {
    pgrep -f "apt" || pgrep -f "dpkg"
}
while check_apt; do
    log "Waiting for apt to be available..."
    sleep 10
done

log "starting background process via screen..."
nohup /bin/bash -c "screen -d -L -Logfile /tmp/pwncat.log -S pwncat -m python3.9 listener.py --port ${listen_port}" >/dev/null 2>&1 &
screen -S pwncat -X colon "logfile flush 0^M"
log "listener started."
log "done"