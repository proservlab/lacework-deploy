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
usage: $SCRIPTNAME [-h] [--standalone]
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
    -s|--standalone)
        STANDALONE="${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

if ! [ -z ${STANDALONE} ]; then
    MOUNT="-v $HOME/.lacework.toml:/root/.lacework.toml -v "${PWD}/env_vars":/workspace/terraform/env_vars -v "${PWD}/scenarios":/workspace/terraform/scenarios"
else
    MOUNT="-v $HOME/.lacework.toml:/root/.lacework.toml -v ${PWD}:/workspace/terraform"
fi

echo "LIVE            = ${LIVE}"

if docker ps | grep deploy-gcp-dind; then
    echo "Found running container, attaching..."
    docker attach deploy-gcp-dind
elif docker ps -a | grep deploy-awgcps-dind; then
    echo "Found stopped container, starting and attaching..."
    docker start deploy-gcp-dind
    docker attach deploy-gcp-dind
else
    echo "Starting and attaching to container..."
    sudo docker run -d --privileged -v /var/run/docker.sock:/var/run/docker.sock --name=deploy-gcp-dind -w /workspace/terraform -it $MOUNT deploy-gcp-dind:latest \
    && docker exec -it deploy-gcp-dind /bin/bash
fi;