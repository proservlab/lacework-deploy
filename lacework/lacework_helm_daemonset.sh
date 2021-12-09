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
usage: $SCRIPTNAME [-h] --token=LACEWORK_AGENT_TOKEN [--server=LACEWORK_SERVER_URL] --cluster=KUBERNETES_CLUSTER_NAME [--environment=KUBERNETES_ENVIRONMENT_NAME]
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
   -t=*|--token=*)
      LACEWORK_AGENT_TOKEN="${i#*=}"
      shift # past argument=value
      ;;
    -s=*|--server=*)
      LACEWORK_SERVER_URL="${i#*=}"
      shift # past argument=value
      ;;
    -c=*|--cluster=*)
      KUBERNETES_CLUSTER_NAME="${i#*=}"
      shift # past argument=value
      ;;
    -e=*|--environment=*)
      KUBERNETES_ENVIRONMENT_NAME="${i#*=}"
      shift # past argument=value
      ;;
    *)
      # unknown option
      ;;
  esac
done

# check for required
if [[ -z ${LACEWORK_AGENT_TOKEN} ]]; then
		errmsg "Required option not set: --token"
		help
fi

if [[ -z ${KUBERNETES_CLUSTER_NAME} ]]; then
		errmsg "Required option not set: --cluster"
		help
fi

echo "LACEWORK_AGENT_TOKEN          = ${LACEWORK_AGENT_TOKEN}"
echo "LACEWORK_SERVER_URL           = ${LACEWORK_SERVER_URL}"
echo "KUBERNETES_CLUSTER_NAME       = ${KUBERNETES_CLUSTER_NAME}"
echo "KUBERNETES_ENVIRONMENT_NAME   = ${KUBERNETES_ENVIRONMENT_NAME}"

helm repo add lacework https://lacework.github.io/helm-charts/
helm upgrade --install --namespace lacework --create-namespace \
         --set laceworkConfig.accessToken=${LACEWORK_AGENT_TOKEN} \
         --set laceworkConfig.clustername=${KUBERNETES_CLUSTER_NAME} \
         lacework-agent lacework/lacework-agent
         #--set laceworkConfig.serverUrl=${LACEWORK_SERVER_URL} \
         #--set laceworkConfig.env=${KUBERNETES_ENVIRONMENT_NAME} \
         
