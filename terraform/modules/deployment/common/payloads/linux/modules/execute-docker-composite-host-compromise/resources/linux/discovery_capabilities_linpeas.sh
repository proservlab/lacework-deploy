#!/bin/bash
SCRIPTNAME="linpeas"
LOGFILE=/tmp/$SCRIPTNAME.log
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
log "Downloading latest linpeas and executing..."
cd /tmp
rm -f linpeas.sh
curl -OJL https://github.com/peass-ng/PEASS-ng/releases/download/20240414-ed0a5fac/linpeas.sh
chmod 755 /tmp/linpeas.sh
./linpeas.sh -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files >> $LOGFILE 2>&1
log "done."