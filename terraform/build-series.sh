
#!/bin/bash

SCRIPTNAME=$(basename $0)
VERSION="1.0.0"

# output errors should be listed as warnings
export TF_WARN_OUTPUT_ERRORS=1

info(){
cat <<EOI
$SCRIPTNAME ($VERSION)

EOI
}

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] --workspace=WORK --action=ACTION --interval=INTERVAL --count=COUNT
EOH
    exit 1
}

infomsg(){
echo "INFO: ${1}"
}
warnmsg(){
echo "WARN: ${1}"
}
errmsg(){
echo "ERROR: ${1}"
}

for i in "$@"; do
  case $i in
    -h|--help)
        HELP="${i#*=}"
        shift # past argument=value
        help
        ;;
    -a=*|--action=*)
        ACTION="${i#*=}"
        shift # past argument=value
        ;;
    -w=*|--workspace=*)
        WORK="${i#*=}"
        shift # past argument=value
        ;;
    -i=*|--interval=*)
        INTERVAL="${i#*=}"
        shift # past argument=value
        ;;
    -c=*|--count=*)
        COUNT="${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

# check for required
if [ -z ${WORK} ]; then
    errmsg "Required option not set: --workspace"
    help
fi

if [ -z ${ACTION} ]; then
    errmsg "Required option not set: --action"
    help
elif [ "${ACTION}" != "destroy" ] && [ "${ACTION}" != "apply" ] && [ "${ACTION}" != "plan" ] && [ "${ACTION}" != "refresh" ]; then
    errmsg "Invalid action: --action should be one of plan, apply, refresh or destroy"
    help
fi

if [ -z ${INTERVAL} ]; then
    errmsg "Required option not set: --interval"
    help
fi

# set provider to first segement of workspace name
PROVIDER=$(infomsg ${WORK} | awk -F '-' '{ print $1 }')

# use variables.tfvars if it exists
if [ -f "env_vars/variables.tfvars" ]; then
  VARS="-var-file=env_vars/variables.tfvars"
else
  VARS=""
fi

# look for work space variables
if [ -f "env_vars/variables-${WORK}.tfvars" ]; then
  VARS="${VARS} -var-file=env_vars/variables-${WORK}.tfvars"
else
  VARS="${VARS}"
fi

# force local back-end
LOCAL_BACKEND="true"

infomsg "ACTION            = ${ACTION}"
infomsg "LOCAL_BACKEND     = ${LOCAL_BACKEND}"
infomsg "VARS              = ${VARS}"
infomsg "PROVIDER          = ${PROVIDER}"
infomsg "INTERVAL"         = "${INTERVAL}"
infomsg "COUNT"            = "${COUNT}"

# Define the maximum loop time and sleep interval
MAX_COUNT=$COUNT
LOOP_COUNT=0
CHECK_INTERVAL=$INTERVAL
INCREMENT=1

# Loop 
TYPES="target attacker simulation"
FILES_TYPE1="infrastructure surface"
FILES_TYPE2="simulation"
while true; do
    for t in ${TYPES[@]}; do 
        infomsg "Type: $t"
        if [ "simulation" == "$t" ]; then
            for f in ${FILES_TYPE2[@]}; do 
                infomsg "File: $f"
                SRC="scenarios/$WORK/$t/$f-$LOOP_COUNT.json"
                DEST="scenarios/$WORK/$t/$f.json"
                infomsg "Checking path: $SRC"
                if [ -f "$SRC" ]; then
                    infomsg "Path found - updating scenario: $SRC"
                    cp -f $SRC $DEST
                fi
            done
        else
            for f in ${FILES_TYPE1[@]}; do 
                infomsg "File: $f"
                SRC="scenarios/$WORK/$t/$f-$LOOP_COUNT.json"
                DEST="scenarios/$WORK/$t/$f.json"
                infomsg "Checking path: $SRC"
                if [ -f "$SRC" ]; then
                    infomsg "Path found - updating scenario: $SRC"
                    cp -f $SRC $DEST
                fi
            done
        fi
    done

    infomsg "Starting build..."
    ./build.sh --workspace=$WORK --action=$ACTION
    infomsg "Build $LOOP_COUNT complete."
    
    LOOP_COUNT=$((LOOP_COUNT + INCREMENT))
    if [ $LOOP_COUNT -ge $MAX_COUNT ]; then
        infomsg "Series complete: $MAX_COUNT"
        
        infomsg "Reverting to default configuration before exiting..."
        # reset
        LOOP_COUNT=0
        for t in ${TYPES[@]}; do 
            infomsg "Type: $t"
            if [ "simulation" == "$t" ]; then
                for f in ${FILES_TYPE2[@]}; do 
                    infomsg "File: $f"
                    SRC="scenarios/$WORK/$t/$f-$LOOP_COUNT.json"
                    DEST="scenarios/$WORK/$t/$f.json"
                    infomsg "Checking path: $SRC"
                    if [ -f "$SRC" ]; then
                        infomsg "Path found - resetting scenario: $SRC"
                        cp -f $SRC $DEST
                    fi
                done
            else
                for f in ${FILES_TYPE1[@]}; do 
                    infomsg "File: $f"
                    SRC="scenarios/$WORK/$t/$f-$LOOP_COUNT.json"
                    DEST="scenarios/$WORK/$t/$f.json"
                    infomsg "Checking path: $SRC"
                    if [ -f "$SRC" ]; then
                        infomsg "Path found - resetting scenario: $SRC"
                        cp -f $SRC $DEST
                    fi
                done
            fi
        done
        echo "Done."
        exit 0
    fi
    sleep $CHECK_INTERVAL
done