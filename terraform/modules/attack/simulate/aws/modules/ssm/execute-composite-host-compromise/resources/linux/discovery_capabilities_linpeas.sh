#!/bin/bash
SCRIPTNAME="linpeas"
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE
log "Starting..."
log "Downloading latest linpeas and executing..."
cd /tmp
rm -f linpeas.sh
curl -OJL https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh
chmod 755 /tmp/linpeas.sh
./linpeas.sh -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex >> $LOGFILE 2>&1
log "done."