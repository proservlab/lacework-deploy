
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

check_tf_apply(){
    if [ ${1} -eq 0 ]; then
        warnmsg "No changes, not applying"
    elif [ ${1} -eq 1 ]; then
        errmsg "Terraform plan failed"
        exit 1
    elif [ ${1} -eq 2 ]; then
        if [ "apply" = "${2}" ]; then
            infomsg "Changes required, applying"
            terraform show build.tfplan
            terraform apply ${3}
        else
            warnmsg "Plan only, not applying"
        fi
    fi
}

# define stage types
INFRASTRUCTURE="infrastructure"
SURFACE="surface"
SIMULATION="simulation"
PLANFILE="build.tfplan"

if [ "destroy" = "${ACTION}" ]; then
    DESTROY="-destroy"
else
    DESTROY=""
fi

if [ "all" = "${STAGE}" ]; then
    if [ "plan" = "${ACTION}" ]; then
        errmsg "Plan action can only be executed for indivdual stages"
        help
    elif [ "apply" = "${ACTION}" ]; then        
        # apply unique buildid
        echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.deployment -out ${PLANFILE}"
        sleep 5
        terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.deployment -out ${PLANFILE} -detailed-exitcode
        ERR=$?
        check_tf_apply ${ERR} ${ACTION} ${PLANFILE}
        for STAGE in ${INFRASTRUCTURE} ${SURFACE} ${SIMULATION}; do
            echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan"
            sleep 5
            terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan -detailed-exitcode
            ERR=$?
            check_tf_apply ${ERR} ${ACTION} ${PLANFILE}
        done
    elif [ "destroy" = "${ACTION}" ]; then
        for STAGE in ${SIMULATION} ${SURFACE} ${INFRASTRUCTURE}; do
            echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan"
            sleep 5
            terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan -detailed-exitcode
            ERR=$?
            check_tf_apply ${ERR} ${ACTION} ${PLANFILE}
        done
        
        # cleanup build id
        echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.deployment -target=module.deployment -out build.tfplan"
        sleep 5
        terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.deployment -out build.tfplan -detailed-exitcode
        ERR=$?
        check_tf_apply ${ERR} ${ACTION} ${PLANFILE}
    fi
elif [ "infra" = "${STAGE}" ] || [ "surface" = "${STAGE}" ] || [ "simulation" = "${STAGE}" ]; then
    STAGE=${STAGE}
    echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.deployment -target=module.deployment -out build.tfplan"
    sleep 5
    terraform plan ${DESTROY} ${BACKEND} ${VARS} -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan -detailed-exitcode
    ERR=$?
    check_tf_apply ${ERR} ${ACTION} ${PLANFILE}
fi
rm -f build.tfplan

echo "Done."