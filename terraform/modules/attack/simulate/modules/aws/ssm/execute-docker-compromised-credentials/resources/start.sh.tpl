#!/bin/bash 

SCRIPTNAME="$(basename "$0")"
SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
VERSION="0.0.1"

info(){
cat <<EOI
$SCRIPTNAME ($VERSION)

EOI
}

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] --container=[aws-cli|terraform|protonvpn] --script=[baseline.sh|discovery.sh] --env-file=ENV_FILE

--service   the docker container to launch;
--env-file  path to environment variable file. default: .env 
EOH
		exit 1
}

errmsg(){
echo "ERROR: $${1}"
}

warnmsg(){
echo "WARN: $${1}"
}

infomsg(){
echo "INFO: $${1}"
}

for i in "$@"; do
  case $i in
    -h|--help)
        HELP="$${i#*=}"
        shift # past argument=value
        help
        ;;
    -c=*|--container=*)
        CONTAINER="$${i#*=}"
        shift # past argument=value
        ;;
    -s=*|--script=*)
        SCRIPT="$${i#*=}"
        shift # past argument=value
        ;;
    -f=*|--env-file=*)
        ENV_FILE="$${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

# check for required
if [ -z "$${SCRIPT}" ]; then
    SCRIPT=""
fi

if [ -z "$${CONTAINER}" ]; then
    errmsg "Required option not set: --container"
    help
elif [ "$${CONTAINER}" = "protonvpn" ]; then
    CONTAINER_IMAGE="ghcr.io/tprasadtp/protonvpn:latest"
    DOCKER_OPTS="--it --device=/dev/net/tun --cap-add=NET_ADMIN"
elif [ "$${CONTAINER}" = "aws-cli" ]; then
    CONTAINER_IMAGE="amazon/aws-cli:latest"
    DOCKER_OPTS="--it --entrypoint=/bin/bash --net=container:protonvpn -w /scripts"
elif [ "$${CONTAINER}" = "terraform" ]; then
    CONTAINER_IMAGE="hashicorp/terraform:latest"
    DOCKER_OPTS="--it --entrypoint=/bin/sh --net=container:protonvpn -w /scripts"
fi

if [ -z "$${ENV_FILE}" ]; then
    errmsg "Required option not set: --env-file"
    warnmsg "Using default: $${SCRIPT_DIR}/.env"
    ENV_FILE="$${SCRIPT_DIR}/.env"
fi

docker stop $${CONTAINER} 2> /dev/null
docker rm $${CONTAINER} 2> /dev/null
docker pull $${CONTAINER_IMAGE}

docker run \
--rm \
--name=$${CONTAINER} \
$${DOCKER_OPTS} \
-v "$${SCRIPT_DIR}/$${CONTAINER}/scripts":/scripts \
--env-file="$${ENV_FILE}" \
$${CONTAINER_IMAGE} $${SCRIPT}