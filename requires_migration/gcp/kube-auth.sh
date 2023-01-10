#!/bin/bash

SCRIPTNAME=$(basename $0)
VERSION="0.0.1"

info(){
cat <<EOI
$SCRIPTNAME ($VERSION)

EOI
}

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] --env=ENV --action=ACTION [--target=TARGET]
EOH
		exit 1
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
    -c=*|--cluster=*)
        CLUSTER="${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

# check for required
if [ -z ${CLUSTER} ]; then
		errmsg "Required option not set: --cluster"
		help
fi

echo "CLUSTER           = ${CLUSTER}"

gcloud container clusters get-credentials ${CLUSTER} --region=us-central1
