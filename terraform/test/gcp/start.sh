#!/bin/bash

SCRIPTNAME=$(basename $0)
VERSION="1.0.0"

info(){
cat <<EOI
$SCRIPTNAME ($VERSION)

EOI
}

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] [--live]
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
    -l|--live)
        LIVE="${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

if ! [ -z ${LIVE} ]; then
    MOUNT="-v $HOME/.lacework.toml:/root/.lacework.toml -v ${PWD}:/workspace/terraform"
else
    MOUNT="-v $HOME/.lacework.toml:/root/.lacework.toml -v "${PWD}/env_vars":/workspace/terraform/env_vars -v "${PWD}/scenarios":/workspace/terraform/scenarios"
fi

echo "MOUNT            = ${MOUNT}"

if docker ps | grep deploy-gcp; then
echo "Found running container, replacing..."
docker stop deploy-gcp
docker rm deploy-gcp
fi;

docker run -d --name=deploy-gcp -w /workspace/terraform -it $MOUNT deploy-gcp:latest \
&& docker exec -it deploy-gcp /bin/bash