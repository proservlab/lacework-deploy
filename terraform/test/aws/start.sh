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
    MOUNT="-v $HOME/.aws:/root/.aws -v $HOME/.lacework.toml:/root/.lacework.toml -v "${PWD}/env_vars":/workspace/terraform/env_vars -v "${PWD}/scenarios":/workspace/terraform/scenarios"
else
    MOUNT="-v $HOME/.aws:/root/.aws -v $HOME/.lacework.toml:/root/.lacework.toml -v ${PWD}:/workspace/terraform"
fi

echo "LIVE            = ${LIVE}"

if docker ps | grep deploy-aws; then
echo "Found running container, replacing..."
docker stop deploy-aws
docker rm deploy-aws
fi;

docker run -d --name=deploy-aws -w /workspace/terraform -it $MOUNT deploy-aws:latest \
&& docker exec -it deploy-aws /bin/bash
