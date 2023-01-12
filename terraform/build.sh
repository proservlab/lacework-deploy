
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
usage: $SCRIPTNAME [-h] --workspace=WORK --action=ACTION [--stage=(all|infra|surface|simulation)]
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
    -a=*|--action=*)
        ACTION="${i#*=}"
        shift # past argument=value
        ;;
    -w=*|--workspace=*)
        WORK="${i#*=}"
        shift # past argument=value
        ;;
    -s=*|--stage=*)
        STAGE="${i#*=}"
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

if [ -z ${STAGE} ]; then
  STAGE="any"
elif [ "${STAGE}" != "all" ] && [ "${STAGE}" != "infra" ] && [ "${STAGE}" != "surface" ] && [ "${STAGE}" != "simulation" ]; then
    errmsg "Invalid action: --stage should be one of all, infra, surface, simulation"
    help
fi

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

echo "ACTION            = ${ACTION}"
echo "STAGE             = ${STAGE}"
echo "LOCAL_BACKEND     = ${LOCAL_BACKEND}"
echo "VARS              = ${VARS}"

# ensure formatting
terraform fmt

# set workspace
terraform workspace select ${WORK} || terraform workspace new ${WORK}

# update modules as required
terraform get -update=true

# ensure backend is initialized
if [ -z ${LOCAL_BACKEND} ]; then
terraform init -backend-config=env_vars/init.tfvars
BACKEND="-var-file=env_vars/backend.tfvars"
else
terraform init
BACKEND=""
fi;

# define stage types
INFRASTRUCTURE="infrastructure"
SURFACE="surface"
SIMULATION="simulation"

if [ "destroy" = "${ACTION}" ]; then
    DESTROY="-destroy"
else
    DESTROY=""
fi

# apply unique buildid
terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.deployment -out buildid.tfplan
terraform apply buildid.tfplan

if [ "all" = "${STAGE}" ]; then
    if [ "plan" = "${ACTION}" ]; then
        errmsg "Plan action can only be executed for indivdual stages"
        help
    elif [ "apply" = "${ACTION}" ]; then
        STAGE=${INFRASTRUCTURE}
        terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
        terraform show build.tfplan
        terraform apply build.tfplan
        STAGE=${SURFACE}
        terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
        terraform show build.tfplan
        terraform apply build.tfplan
        STAGE=${SIMULATION}
        terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
        terraform show build.tfplan
        terraform apply build.tfplan
    elif [ "destroy" = "${ACTION}" ]; then
        STAGE=${SIMULATION}
        terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
        terraform show build.tfplan
        terraform apply build.tfplan
        STAGE=${SURFACE}
        terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
        terraform show build.tfplan
        terraform apply build.tfplan
        STAGE=${INFRASTRUCTURE}
        terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
        terraform show build.tfplan
        terraform apply build.tfplan
    fi
elif [ "infra" = "${STAGE}" ]; then
    STAGE=${INFRASTRUCTURE}
    terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
    terraform show build.tfplan
    if [ "apply" = "${ACTION}" ]; then
        terraform apply build.tfplan
    fi
elif [ "surface" = "${STAGE}" ]; then
    STAGE=${SURFACE}
    terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
    terraform show build.tfplan
    if [ "apply" = "${ACTION}" ]; then
        terraform apply build.tfplan
    fi
elif [ "simulation" = "${STAGE}" ]; then
    STAGE=${SIMULATION}
    terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
    terraform show build.tfplan
    if [ "apply" = "${ACTION}" ]; then
        terraform apply build.tfplan
    fi
fi
rm -f build.tfplan

echo "Done."