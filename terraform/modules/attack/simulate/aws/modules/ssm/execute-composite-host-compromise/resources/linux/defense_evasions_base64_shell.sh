#!/bin/bash
SCRIPTNAME="bash64"
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE
$PAYLOAD=$(echo -en '#!/bin/bash\necho test\n' | base64)
echo -n $PAYLOAD | base64 -d | /bin/bash - >> $LOGFILE 2>&1